
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
  components new AMSenderC(AM_REQMSG) as ReqSender;
  components new AMReceiverC(AM_ACKMSG) as AckReceiver;
  components new AMSenderC(AM_RESULTMSG) as ResultSender;

  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.Timer0 -> Timer0;

  App.AMControl -> ActiveMessageC;

  App.NumberReceiver -> NumberReceiver;
  App.NumberP -> NumberReceiver;

  App.ReqP -> ReqSender;
  App.ReqSender -> ReqSender;

  App.AckReceiver -> AckReceiver;
  App.AckP -> AckReceiver;

  App.ResultSender -> ResultSender;
  App.ResultP -> ResultSender;

  App.Ack -> ResultSender;
}
