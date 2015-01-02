configuration Node2App{}

implementation {

  components MainC, Node2 as App, LedsC;

  components new AMSenderC(AM_NUMBERMSG) as sender;

  components new AMReceiverC(AM_REQMSG) as reciever;

  components new AMReceiverC(AM_NUMBERMSG) as reciever2;

  components ActiveMessageC;


  App.Boot -> MainC.Boot;

  App.Receive -> reciever;

  App.Receive2 -> reciever2;

  App.AMSend -> sender;

  App.AMControl -> ActiveMessageC;

  App.Leds -> LedsC;

  App.Packet -> sender;
  App.Ack-> sender;

}