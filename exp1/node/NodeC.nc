
#include <Timer.h>
#include "Node.h"

module NodeC 
{
  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
  uses interface Timer<TMilli> as UnbiasedTimer;
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface Receive;
  uses interface SplitControl as AMControl;
  uses interface PacketAcknowledgements as Ack;

  uses interface Read<uint16_t> as Temp; 
  uses interface Read<uint16_t> as Humid;
  uses interface Read<uint16_t> as Light;
}
implementation 
{

  uint16_t counter;
  uint32_t tiks;
  message_t pkt[BUFFER_SIZE];
  uint16_t tmp,hum,lig;
  bool busy = FALSE;
  bool bTmp,bHum,bLig;
  bool rTmp,rHum,rLig;
  int head,tail;
  int DES;

  event void Boot.booted() 
  {
    call AMControl.start();
  }

  void callTmpRead()
  {
    if (bTmp==TRUE)
    {
      rTmp=TRUE;
      return;
    } 
    bTmp=TRUE;
    call Temp.read();
  }
  void callHumidRead()
  {
    if (bHum==TRUE)
    {
      rHum=TRUE;
      return;
    } 
    bHum=TRUE;
    call Humid.read();
  }
  void callLightRead()
  {
    if (bLig==TRUE)
    {
      rLig=TRUE;
      return;
    } 
    bLig=TRUE;
    call Light.read();
  }

  event void AMControl.startDone(error_t err) 
  {
    if (err == SUCCESS) 
    {
      counter=0;
      head=0;
      tail=-1;
      tiks=0;
      tmp=hum=lig=0;
      bTmp=bHum=bLig=FALSE;
      rTmp=rHum=rLig=FALSE;
      if (TOS_NODE_ID==SENDER)
        DES=MEDIATOR;
      else
        DES=CMD;
      callTmpRead();
      callHumidRead();
      callLightRead();
      call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
      call UnbiasedTimer.startPeriodic(100);
    }
    else 
    {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) 
  {
  }

  void sendMessage(bool isCont)
  {
    int nowPlace;
    if (tail<head) 
      return;
    nowPlace=head%BUFFER_SIZE;
    if (!busy || isCont) 
    {
      call Ack.requestAck(&pkt[nowPlace]);
      if (TOS_NODE_ID==MEDIATOR)
      {
        BlinkToRadioMsg* buf=(BlinkToRadioMsg*)(call Packet.getPayload(&pkt[nowPlace], sizeof(BlinkToRadioMsg)));
        if (buf->msgType==CMD)
          DES=SENDER;
        else
          DES=CMD;
      }
      
      if (call AMSend.send(DES, &pkt[nowPlace], sizeof(BlinkToRadioMsg)) == SUCCESS) 
      {
        busy = TRUE;
        call Leds.led2On();
        head++;
      }
    }
  }

  event void Timer0.fired() 
  {
    int thisOne=(++tail)%BUFFER_SIZE;

    BlinkToRadioMsg* buf=(BlinkToRadioMsg*)(call Packet.getPayload(&pkt[thisOne], sizeof(BlinkToRadioMsg)));
    buf->msgType=TOS_NODE_ID;
    buf->msgNum=counter++;
    buf->msgTime=tiks;

    callTmpRead();
    callHumidRead();
    callLightRead();

    buf->temp=tmp;
    buf->humid=hum;
    buf->light=lig;
    
    sendMessage(FALSE);
  }
  event void Temp.readDone(error_t result, uint16_t data)
  {
    if (result!=SUCCESS)
    {
      tmp=0;
    }
    tmp=data;
    if (rTmp==TRUE)
    {
      rTmp=FALSE;
      call Temp.read();
    }
    else
      bTmp=FALSE;  
  }
  event void Humid.readDone(error_t result, uint16_t data)
  {
    if (result!=SUCCESS)
    {
      hum=0;
    }
    hum=data;
    if (rHum==TRUE)
    {
      rHum=FALSE;
      call Humid.read();
    }
    else
      bHum=FALSE;   
  }
  event void Light.readDone(error_t result, uint16_t data)
  {
    if (result!=SUCCESS)
    {
      lig=0;
    }
    lig=data;
    if (rLig==TRUE)
    {
      rLig=FALSE;
      call Light.read();
    }
    else
      bLig=FALSE;  
  }

  event void UnbiasedTimer.fired()
  {
    tiks++;
  }

  event void AMSend.sendDone(message_t* msg, error_t err)   
  {
    if (err==SUCCESS && msg==&pkt[(head-1)%BUFFER_SIZE])
    {
      
      if(call Ack.wasAcked(msg))
      {
        call Leds.led0On();
      }
      else
      {
        head--;
        call Leds.led0Off();
      }
      
      if (tail<head)
      {
        busy=FALSE;
        call Leds.led2Off();
      }
      else
      {
        sendMessage(TRUE);
      }  
    }  
  }


  void changePeriod(uint16_t interval)
  {
    call Timer0.stop();
    call Timer0.startPeriodic(interval);
  }
  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len)
  {
    int thisOne;
    if (len == sizeof(BlinkToRadioMsg))
    {
      BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)payload;
      if (btrpkt->msgType==CMD_MSG)  
      {
        changePeriod(btrpkt->temp);
        tiks=btrpkt->msgTime;
      }
      if (TOS_NODE_ID==SENDER) return msg;
      thisOne=(++tail)%BUFFER_SIZE;
      if (btrpkt->msgType==SENDER_MSG)
      {
        BlinkToRadioMsg* buf=(BlinkToRadioMsg*)(call Packet.getPayload(&pkt[thisOne], sizeof(BlinkToRadioMsg)));
        *buf=*btrpkt;
        if (btrpkt->msgType!=CMD_MSG) buf->msgType=FORWARDED_MSG;
        sendMessage(FALSE);
      }   
    }
    return msg;
  }
}
