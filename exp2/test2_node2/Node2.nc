#include "Receiver.h"





module Node2 @safe() {

	uses {

		interface Leds;	

		interface Boot;

		interface Receive as Receive;
                interface Receive as Receive2;

		interface AMSend;

		

		interface SplitControl as AMControl; 

		interface Packet;
		interface PacketAcknowledgements as Ack;

  

	}

}

implementation {

	message_t sendBuf;



	bool busy;



	uint32_t data[2001];   //the data recieved;

	uint8_t flag[126];	   //use each bit to mark whether the package is recieved or not,1 for recieved;

	uint16_t curSeqnum; //record the current data being sent

	

	void report_receiveRequest() {call Leds.led0Toggle();}

	void report_sent() { call Leds.led1Toggle(); } 

	void report_received() { call Leds.led2Toggle(); } 



	event void Boot.booted() {

		uint16_t i;

 

		busy = FALSE;  



		for(i = 0; i<2001; i++)

		{

			data[i] = 0;

		}

		for(i = 0; i<126; i++)

		{

			flag[i] = 0;

		}



		call AMControl.start();

		

	}



	event void AMControl.startDone(error_t error) {

	 	if (error != SUCCESS) {

	  		call AMControl.start();

		}

	}

	event void AMControl.stopDone(error_t err) {}



	void SendPackageToNode1(uint16_t sequenceNum)

	{
		

		NumberMsg* answer=(NumberMsg*)call Packet.getPayload(&sendBuf,sizeof(NumberMsg));

		answer->sequence_number = sequenceNum;

		answer->random_integer = data[sequenceNum];
		curSeqnum = sequenceNum;
		call Ack.requestAck(&sendBuf);

		if(call AMSend.send(NODE1_ADDR, &sendBuf, sizeof(NumberMsg)) == SUCCESS)

		{

			busy = TRUE;

			report_sent();

		} 

	}



	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len)

	{

		

		//recieve request message,respond data

		if(len == sizeof(ReqMsg))

		{

			

			ReqMsg* req = (ReqMsg*)payload;

			report_receiveRequest();

			if(req->magic == _MAGIC)

			{

				if(((flag[req->seqRequired>>3]>>(req->seqRequired&7))&1)==1)

				{
					if(!busy)
					{
						SendPackageToNode1(req->seqRequired);
					}

					

				}

				else

				{

					data[req->seqRequired] = 2;//marked as required but not available now

				}

				

			}

			

			

		}
		return msg;

	}



	event message_t* Receive2.receive(message_t* msg, void* payload, uint8_t len)

	{

		NumberMsg* pkg;

		//recieve radio message, collect data

		if (len == sizeof(NumberMsg))

		{

			//report_received();

			pkg = (NumberMsg*)payload;

		

			//if haven't recieved before

			if(((flag[pkg->sequence_number>>3]>>(pkg->sequence_number&7))&1)==0 )

			{

				uint16_t mark = data[pkg->sequence_number];

				flag[pkg->sequence_number>>3]|=(1<<(pkg->sequence_number&7));

				data[pkg->sequence_number]=pkg->random_integer;

				//if has been requested before

				if(mark == 2&&!busy)

				{

					SendPackageToNode1(pkg->sequence_number);

				}



				 

			}

		}
		return msg;

	}

	

	event void AMSend.sendDone(message_t* msg, error_t error)

	{
		if (error==SUCCESS && msg==&sendBuf)
    		{
      			if(call Ack.wasAcked(msg))
     			 {
				call Leds.led2On();
				busy = FALSE;
			 }
			else
			{
				call Leds.led2Off();
				SendPackageToNode1(curSeqnum);
			}
		}

		

	}

}