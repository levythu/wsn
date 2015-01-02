
#include <Timer.h>
#include "God.h"

configuration GodAppC {
}
implementation {
  components MainC;
  components LedsC;
  components GodC as App;
  components new TimerMilliC() as Timer0;
  components ActiveMessageC;
  components new AMSenderC(AM_NUMBERMSG) as NumberSender;

  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.Timer0 -> Timer0;

  App.AMControl -> ActiveMessageC;

  App.NumberSender -> NumberSender;
  App.NumberSenderP -> NumberSender;
}
