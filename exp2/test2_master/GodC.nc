
#include <Timer.h>
#include "God.h"

module GodC
{
  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
  uses interface SplitControl as AMControl;

  uses interface Packet as NumberSenderP;
  uses interface AMSend as NumberSender;
}
implementation 
{
  bool NumberSenderOccupied=FALSE;
  int progress=0;
  int INTMAX=2000;
  message_t numpkg;

  event void Boot.booted() 
  {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) 
  {
    if (err == SUCCESS) 
    {
      call Timer0.startPeriodic(10);
    }
    else 
    {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) 
  { }

  event void Timer0.fired() 
  {
    NumberMsg* buf;
    if (NumberSenderOccupied==TRUE)
      return;
    NumberSenderOccupied=TRUE;
    call Leds.led2On();
    buf=(NumberMsg*)(call NumberSenderP.getPayload(&numpkg, sizeof(NumberMsg)));
    buf->sequence_number=progress+1;
    buf->random_integer=progress;
    progress=(progress+1)%INTMAX;
    while (call NumberSender.send(AM_BROADCAST_ADDR, &numpkg, sizeof(NumberMsg)) != SUCCESS) 
    { }
  }

  event void NumberSender.sendDone(message_t* msg, error_t err)   
  {
    if (err==SUCCESS && msg==&numpkg)
    {
      call Leds.led2Off();
      NumberSenderOccupied=FALSE;
    }  
  }
}
