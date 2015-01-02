
#include <Timer.h>
#include "Receiver.h"

configuration ReceiverAppC {
}
implementation {
  components MainC;
  components LedsC;
  components ReceiverC as App;
  components ActiveMessageC;
  components new TimerMilliC() as Timer0;
  components new AMReceiverC(AM_NUMBERMSG) as NumberReceiver;
  components new AMSenderC(AM_NUMBERMSG) as ReqSender;

  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.Timer0 -> Timer0;
  
  App.AMControl -> ActiveMessageC;

  App.NumberReceiver -> NumberReceiver;
  App.NumberP -> NumberReceiver;

  App.ReqP -> ReqSender;
  App.ReqSender -> ReqSender;
}
