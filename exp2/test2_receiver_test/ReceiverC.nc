
#include <Timer.h>
#include "Receiver.h"

module ReceiverC
{
  uses interface Boot;
  uses interface Leds;
  uses interface SplitControl as AMControl;

  uses interface Packet as NumberP;
  uses interface Receive as NumberReceiver;
}
implementation 
{
  #define nums 2000
  uint32_t rcd[nums+1];
  uint8_t got[nums/8+1];
  uint32_t nums_ = nums;
  uint32_t c = 0x80000000;
  int gotNums;

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
        gotNums++;
        if (gotNums==nums)
        {
          call Leds.led2On();
          if (rcd[0]==0)
            call Leds.led1Toggle();
        }  
      }
    }
    return msg;
  }
}
