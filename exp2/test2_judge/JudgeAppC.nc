
#include "printf.h"
#include <Timer.h>
#include "Judge.h"

configuration JudgeAppC {
}
implementation {
  components MainC;
  components LedsC;
  components JudgeC as App;
  components ActiveMessageC;
  components new AMSenderC(AM_ACKMSG) as AckSender;
  components new AMReceiverC(AM_RESULTMSG) as ResultReceiver;

  App.Boot -> MainC;
  App.Leds -> LedsC;

  App.AMControl -> ActiveMessageC;

  App.AckSender -> AckSender;
  App.AckP -> AckSender;
  App.ResReceiver -> ResultReceiver;
  App.ResP -> ResultReceiver;
}
