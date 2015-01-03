
#include <Timer.h>
#include "Receiver.h"
#include "printf.h"

enum STAT
{
  RECEIVING=10,
  REQUIRING=20,
  COMPUTING=30,
  COMMITING=40,
  ENDOFLINE=50
};

module ReceiverC
{
  uses interface Boot;
  uses interface Leds;
  uses interface SplitControl as AMControl;
  uses interface Timer<TMilli> as Timer0;

  uses interface Packet as NumberP;
  uses interface Receive as NumberReceiver;

  uses interface Packet as ReqP;
  uses interface AMSend as ReqSender;

  uses interface Packet as AckP;
  uses interface Receive as AckReceiver;

  uses interface Packet as ResultP;
  uses interface AMSend as ResultSender;

  uses interface PacketAcknowledgements as Ack;
}
implementation 
{
  #define nums 2000
  uint32_t rcd[nums+1];
  uint8_t got[nums/8+1];
  uint32_t nums_ = nums;
  int gotNums;
  uint8_t status = 0;
  uint32_t cursor = 0;
  ResultMsg res;
  message_t pkg,finalPkg;
  bool reqBusy;

  void postResult();
  void startCal();

  event void Boot.booted() 
  {
    uint32_t i;
    for (i=0;i<=nums/8;i++)
      got[i]=0;

    for (i=1;i<nums;i++)
    {
      rcd[i]=((i-1)<<16)|(i+1);
    }
    rcd[nums_]=(nums_-1)<<16;
    rcd[0]=(nums_<<16)|1;

    gotNums=0;
    status=RECEIVING;
    reqBusy=FALSE;

    res.max=0;
    res.min=0xffffffff;
    res.sum=0;

    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) 
  {
    if (err == SUCCESS) 
    { }
    else 
    {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) 
  { }

  uint32_t getKthNum(uint32_t begg, uint32_t endd, uint32_t k)    //MUST RUN AFTER THE FINIT OF AGGREGATION, k~[1..n]
  {
    uint32_t i=begg,j=endd,p=rcd[(i+j)>>1],q;
    if (i==j)
      return p;
    while (i<=j)
    {
      while (rcd[i]<p) i++;
      while (rcd[j]>p) j--;
      if (i<=j)
      {
        q=rcd[i];
        rcd[i]=rcd[j];
        rcd[j]=q;
        i++;
        j--;
      }
    }  
    k+=begg-1;
    if (k<=j) return getKthNum(begg,j,k-begg+1);
    if (k>=i) return getKthNum(i,endd,k-i+1);
    return rcd[j+1];
  }
  void startCal()
  {
    uint32_t i,s;

    call Leds.led0On();
    call Leds.led1On();
    call Leds.led2On();

    s=0;
    for (i=1;i<=nums;i++)
    {
      if (res.max<rcd[i]) res.max=rcd[i];
      if (res.min>rcd[i]) res.min=rcd[i];
      res.sum+=rcd[i];
      if (i>1000)
        call Leds.led0Off();
    }  
    res.average=res.sum/nums;
    res.group_id=GROUP_ID;
    res.median=(getKthNum(1, nums, 1000)+getKthNum(1, nums, 1001))>>1;

    call Leds.led0Off();
    call Leds.led1Off();
    call Leds.led2Off();

    status=COMMITING;
    //postResult();
  }

  void reqForNextElem()
  {
    ReqMsg* buf;
    if (cursor==0)
    {
      if (rcd[cursor]==0)
      {
        call Timer0.stop();
        return;
      }
      cursor=rcd[cursor]>>16;   //Find the latest uncaught number!
    }  
    buf=(ReqMsg*)(call ReqP.getPayload(&pkg, sizeof(ReqMsg)));
    buf->magic=_MAGIC;
    buf->seqRequired=cursor;
    call Leds.led1On();
    while (call ReqSender.send(AM_BROADCAST_ADDR, &pkg, sizeof(ReqMsg)) != SUCCESS) 
    { }
    reqBusy=TRUE;
  }

  event void ReqSender.sendDone(message_t* msg, error_t err)
  {
    if (err == SUCCESS)
      cursor=rcd[cursor]>>16;
    call Leds.led1Off();
    reqBusy=FALSE;
  }

  event void Timer0.fired() 
  {
    if (reqBusy==FALSE)
      reqForNextElem();
  }

  event message_t* NumberReceiver.receive(message_t* msg, void* payload, uint8_t len)
  {
    uint32_t p,n;
    if (len == sizeof(NumberMsg)) 
    {
      NumberMsg* btrpkt = (NumberMsg*)payload;
      if (  ((got[btrpkt->sequence_number>>3]>>(btrpkt->sequence_number&7))&1)==0  )
      {
        got[btrpkt->sequence_number>>3]|=(1<<(btrpkt->sequence_number&7));
        call Leds.led0Toggle();

        p=rcd[btrpkt->sequence_number]>>16;
        n=rcd[btrpkt->sequence_number]&0xffff;
        rcd[p]&=0xffff0000;
        rcd[p]|=n;
        rcd[n]&=0xffff;
        rcd[n]|=p<<16;

        rcd[btrpkt->sequence_number]=btrpkt->random_integer;
        if (cursor==btrpkt->sequence_number) cursor=p;
        gotNums++;

        printf("RECEIVED: %u,",btrpkt->random_integer);
        printf("totally %d\n",gotNums);
        if (gotNums==nums)
        {
          printf("TO COMPUTING!\n");
          call Leds.led2On();
          status=COMPUTING;
          startCal();
        }  
      }
      else
      {
        if (status<REQUIRING)
        {
          status=REQUIRING;
          call Timer0.startPeriodic(77);
        }  
      }  
    }
    return msg;
  }

  //===================LA FINIS DE CALCULATE==========================
  void postResult()
  {
    ResultMsg* buf;

    call Leds.led0On();
    buf=(ResultMsg*)(call ResultP.getPayload(&finalPkg, sizeof(ResultMsg)));
    *buf=res;
    call Ack.requestAck(&finalPkg);
    while (call ResultSender.send(0, &finalPkg, sizeof(ResultMsg)) != SUCCESS) 
    { }
  }
  
  event void ResultSender.sendDone(message_t* msg, error_t err)
  {
    if (err!=SUCCESS || msg!=&finalPkg)
    {  
      postResult();
      return;
    }  
    if((call Ack.wasAcked(msg))==FALSE)
    {
      postResult();
      return;
    }  
    call Leds.led0Off();
    if (status<ENDOFLINE)
      postResult();
  }

  event message_t* AckReceiver.receive(message_t* msg, void* payload, uint8_t len)
  {
    if (len == sizeof(AckMsg)) 
    {
      AckMsg* btrpkt = (AckMsg*)payload;
      if (btrpkt->group_id==GROUP_ID)
        status=ENDOFLINE;
    }
    return msg;
  }
}
