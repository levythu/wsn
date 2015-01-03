
#include "printf.h"
#include <Timer.h>
#include "Judge.h"

module JudgeC
{
  uses interface Boot;
  uses interface Leds;
  uses interface SplitControl as AMControl;

  uses interface Packet as AckP;
  uses interface AMSend as AckSender;

  uses interface Packet as ResP;
  uses interface Receive as ResReceiver;
}
implementation 
{
  bool AckSenderOccupied=FALSE;
  message_t pkg;

  event void Boot.booted() 
  {
    printf("hello!");
    printfflush();
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) 
  {
    if (err == SUCCESS) 
    {
    }
    else 
    {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) 
  { }

  event void AckSender.sendDone(message_t* msg, error_t err)   
  {
    if (err==SUCCESS && msg==&pkg)
    {
      call Leds.led2Toggle();
      AckSenderOccupied=FALSE;
    }  
  }

  void sendAck(uint8_t grid)
  {
    AckMsg* buf;

    if (AckSenderOccupied==TRUE) 
      return;
    AckSenderOccupied=FALSE;

    buf=(AckMsg*)(call AckP.getPayload(&pkg, sizeof(AckMsg)));
    buf->group_id=grid;

    while (call AckSender.send(AM_BROADCAST_ADDR, &pkg, sizeof(AckMsg)) != SUCCESS) 
    { }
  }

  event message_t* ResReceiver.receive(message_t* msg, void* payload, uint8_t len)
  {
    if (len == sizeof(ResultMsg)) 
    {
      ResultMsg* btrpkt = (ResultMsg*)payload;

      printf("Group id=%d\n",btrpkt->group_id);
      printf("MAX NUM=%ld\n",btrpkt->max);
      printf("MIN NUM=%ld\n",btrpkt->min);
      printf("SUM=%ld\n",btrpkt->sum);
      printf("AVERAGE=%ld\n",btrpkt->average);
      printf("MEDIAN=%ld\n",btrpkt->median);
      printf("\n\n");
      printfflush();
      
      sendAck(btrpkt->group_id);
    }
    return msg;
  }
}
