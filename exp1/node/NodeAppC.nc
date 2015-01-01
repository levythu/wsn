
#include <Timer.h>
#include "Node.h"

configuration NodeAppC {
}
implementation {
  components MainC;
  components LedsC;
  components NodeC as App;
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as UnbiasedTimer;
  components ActiveMessageC;
  components new AMSenderC(AM_BLINKTORADIO);
  components new AMReceiverC(AM_BLINKTORADIO);
  components new SensirionSht11C() as composedSensor;
  components new HamamatsuS1087ParC() as photoSensor;

  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.Timer0 -> Timer0;
  App.UnbiasedTimer -> UnbiasedTimer;
  App.Packet -> AMSenderC;
  App.AMPacket -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.AMSend -> AMSenderC;
  App.Ack -> AMSenderC;
  App.Receive -> AMReceiverC;
  App.Temp -> composedSensor.Temperature;
  App.Humid -> composedSensor.Humidity;
  App.Light -> photoSensor;
}
