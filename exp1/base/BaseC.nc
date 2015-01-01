configuration BaseC {

}
implementation {
  components MainC, BaseP, LedsC;
  components ActiveMessageC as Radio;
  components SerialActiveMessageC as Serial;
  components new AMSenderC(AM_BLINKTORADIO);
  components new AMReceiverC(AM_BLINKTORADIO);
  components new TimerMilliC() as timer ;

  BaseP->MainC.Boot;
  BaseP.RadioControl -> Radio;
  BaseP.SerialControl -> Serial;
  
  BaseP.SerialSend -> Serial.AMSend[AM_BLINKTORADIOMSG];
  BaseP.SerialReceive -> Serial.Receive[AM_BLINKTORADIOMSG];
  BaseP.SerialPacket -> Serial;
  BaseP.SerialAMPacket -> Serial;
  
  BaseP.RadioSend -> AMSenderC;
  BaseP.RadioReceive -> AMReceiverC;
  BaseP.RadioPacket -> Radio;
  BaseP.RadioAMPacket -> Radio;
  BaseP.MilliTimer->timer;
  BaseP.Leds -> LedsC;
}
