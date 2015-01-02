
#include <Timer.h>
#include "Receiver.h"

configuration ReceiverAppC {
}
implementation {
  components MainC;
  components LedsC;
  components ReceiverC as App;
  components ActiveMessageC;
  //components new AMSenderC(AM_NUMBERMSG) as NumberSender;
  components new AMReceiverC(AM_NUMBERMSG) as NumberReceiver;

  App.Boot -> MainC;
  App.Leds -> LedsC;

  App.AMControl -> ActiveMessageC;

  App.NumberReceiver -> NumberReceiver;
  App.NumberP -> NumberReceiver;
}
