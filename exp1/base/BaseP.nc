#include "AM.h"
#include "Timer.h"
#include "Node.h"

module BaseP @safe() {
  uses {
	interface Boot;
	interface SplitControl as SerialControl;
	interface SplitControl as RadioControl;

	interface AMSend as SerialSend;
	interface Receive as SerialReceive;
	interface Packet as SerialPacket;
	interface AMPacket as SerialAMPacket;

	interface AMSend as RadioSend;
	interface Receive as RadioReceive;

	interface Packet as RadioPacket;
	interface AMPacket as RadioAMPacket;

	interface Leds;
	interface Timer<TMilli> as MilliTimer;
  }
}

implementation
{
 
	message_t packet;
	bool serialBusy ;
	bool radioBusy ;
	uint16_t counter = 0;

	void report_sendradio() { call Leds.led2Toggle(); }
	void report_fromradio() { call Leds.led1Toggle(); }
	void report_sendserial()  { call Leds.led0Toggle(); }

	event void Boot.booted() 
	{
	serialBusy = FALSE;
	radioBusy = FALSE;
    call RadioControl.start();   
    call SerialControl.start();
  	}

	event void MilliTimer.fired(){}
 
	/*****************if recieve from radio**********************************/
	event message_t *RadioReceive.receive(message_t *msg, void *payload,uint8_t len) 	{
		am_addr_t addr, src;
		BlinkToRadioMsg* rcm = (BlinkToRadioMsg*)payload;		
		if (len != sizeof(BlinkToRadioMsg))
		{
			return msg;
		}

		
		report_fromradio();  
		if((rcm->msgType == MEDIATOR_MSG) || (rcm->msgType == FORWARDED_MSG))  
		{
			addr = call RadioAMPacket.destination(msg);
			src = call RadioAMPacket.source(msg);
			call SerialPacket.clear(msg);
			call SerialAMPacket.setSource(msg, src);
			if (call SerialSend.send(addr, msg, sizeof(BlinkToRadioMsg)) == SUCCESS)
			{
				report_sendserial();  /*show send to pc*/
				serialBusy = TRUE;
				counter++;   
			}
		}
		return msg;
  	}
	event void SerialSend.sendDone(message_t* msg, error_t error) 
	{
		if (&packet == msg) 
		{		
			serialBusy = FALSE;
		}
	}

  /************************recieve from pc*****************************/
	event message_t *SerialReceive.receive(message_t *msg, void *payload, uint8_t len) 
	{
		am_addr_t addr, src;
		addr = call SerialAMPacket.destination(msg);
		src = call SerialAMPacket.source(msg);
		len = call SerialPacket.payloadLength(msg);
		call RadioPacket.clear(msg);
		call RadioAMPacket.setSource(msg, src);	   
		report_sendradio();
		
		if (call RadioSend.send(AM_BROADCAST_ADDR, msg, len) == SUCCESS)
		{
			radioBusy = TRUE;
		}
		return msg;
	}

	event void RadioSend.sendDone(message_t* msg, error_t error) 
	{
		if (&packet == msg) 
		{
			radioBusy = FALSE;
		}
	}
	event void RadioControl.startDone(error_t err)
	{
		if (err == SUCCESS) 
		{
			call MilliTimer.startPeriodic(1000);
		}
		else
		{
			call RadioControl.start();
		}
	}
	event void RadioControl.stopDone(error_t err) {}

	event void SerialControl.startDone(error_t err){}
	event void SerialControl.stopDone(error_t err) {}
}  
