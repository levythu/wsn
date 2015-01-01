import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.io.DataOutputStream;
import java.io.DataInputStream;
import java.io.IOException;

import java.util.Calendar;

import net.tinyos.message.*;

import net.tinyos.packet.*;

import net.tinyos.util.*;



public class Serial implements MessageListener {



	private MoteIF moteIF;



	private MessageInfo msgInfo;



	private boolean[] packetFlag;

	private int maxNum;



	public class MessageInfo {

		public int msgType;

		public int msgNum;

		public long msgTime;

		public double temp;

		public double humid;

		public double light;

	}



	public Serial(MoteIF moteIF) {

		this.maxNum = -1;

		this.packetFlag = new boolean[10000];

		this.moteIF = moteIF;

		this.moteIF.registerListener(new SerialMsg(), this);

		this.msgInfo = new MessageInfo();

	}



	public void waitForever() {

		while (true) {

			try {

				Thread.sleep(1000);

			} catch (Throwable e) {

				

			}

		}

	}



	public void output() {

		int count = 0;

		for (int i = 0; i <= maxNum; i++) {

			if (this.packetFlag[i] == false) {

				count++;

			}

		}

		if (maxNum == -1) {

			System.out.println("Packet loss ratio: 0");

		} else {

			System.out.println("Packet loss ratio: " + (double)count / (maxNum + 1));

		}

		

	}



	public void messageReceived(int to, Message message) {

		double tempTemperature;

		double tempHumidity;



		SerialMsg msg = new SerialMsg();

		try {

			msg = (SerialMsg)message;

			if (msg == null) {

				return;

			}

		} catch (Exception e) {

			System.out.println("Error occured!");

		}

		

		this.msgInfo.msgType = msg.get_msgType();

		this.msgInfo.msgNum = msg.get_msgNum();

		this.msgInfo.msgTime = msg.get_msgTime();

		//tempTemperature = msg.get_temp();

		tempTemperature = msg.get_temp()&16383;

		this.msgInfo.temp =-39.6 + 0.01*tempTemperature;

		//tempHumidity = msg.get_humid();

		tempHumidity = msg.get_humid()&4095;

		this.msgInfo.humid = -2.0468 + 0.0367*tempHumidity - 1.5955/(1000000) *(tempHumidity*tempHumidity);

        	this.msgInfo.light = 0.085*msg.get_light();



		//if(this.msgInfo.msgType == 3) 

		//	return;
		long totalSeconds = this.msgInfo.msgTime/10;
		long hour = totalSeconds/3600;
		long minute = totalSeconds%3600/60;
		long second = totalSeconds%3600%60;

		System.out.println("Message received!");

		System.out.println("MsgType:"+this.msgInfo.msgType);

		System.out.println("MsgNumber:"+this.msgInfo.msgNum);

		//System.out.println("TimeStamp:"+this.msgInfo.msgTime/10+"s");
 		System.out.println("TimeStamp:"+hour+":"+minute+":"+second);

		System.out.println("Temperature:"+this.msgInfo.temp+"℃");

		System.out.println("Humidity:"+this.msgInfo.humid+"%");

		System.out.println("Light Intensity:"+this.msgInfo.light+"kLux");

		System.out.println();



		if (this.msgInfo.msgType == 3) {

			int num = this.msgInfo.msgNum;



			this.packetFlag[num] = true;

			if (num > maxNum) {

				maxNum = num;

			}

		}

		

		output();



	}



	//PC send package to node

	public void ChangeInterval(int NewInterval)

	{

		SendToBase(NewInterval);

	}

	public void SendToBase(int NewInterval)

	{

		// when the pc wants to send a Packets, use this function.

		int msgType = 2;

		int msgNum = 0;

		int msgTime;

		int temp = NewInterval;//use temp as Interval here

		int humid = 0;

		int light = 0;

		int counter = 0;

		Calendar cld = Calendar.getInstance();

		int hour = cld.get(Calendar.HOUR_OF_DAY);

		int minute = cld.get(Calendar.MINUTE);

		int second = cld.get(cld.SECOND);

		int msecond = cld.get(Calendar.MILLISECOND);

		msgTime = msecond/100 + second * 10 + minute * 600 + hour * 36000;

		SerialMsg payload = new SerialMsg();	    

		try {

			counter++;

			System.out.println("Sending packet: " + counter);

			payload.set_msgType(msgType);

			payload.set_msgNum(msgNum);

			payload.set_msgTime(msgTime);

			payload.set_temp(temp);

			payload.set_humid(humid);

			payload.set_light(light);

			moteIF.send(0, payload);

		}

		catch (IOException exception) {

			System.err.println("Exception thrown when sending packets. Exiting.");

			System.err.println(exception);

		}

  

	}



	private static void usage() {

		System.err.println("usage: TestSerial [-comm <source>]");

	}



	public static void main(String[] args) throws Exception {

		String source = null;

		if (args.length == 2) {

			if (!args[0].equals("-comm")) {

				usage();

				System.exit(1);

			}

			source = args[1];

		} else if (args.length != 0) {

			usage();

			System.exit(1);

		}



		PhoenixSource phoenix;

		if (source == null) {

			phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);

		} else {

			phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);

		}



		MoteIF mif = new MoteIF(phoenix);

		Serial serial = new Serial(mif);

		

		//Change Interval

		InputStreamReader ReadIn;

		BufferedReader ReadBuffer;

		while(true)

		{ 
			try{

				ReadIn = new InputStreamReader(System.in);

				ReadBuffer = new BufferedReader(ReadIn);

				String s = ReadBuffer.readLine();

				int interval = Integer.parseInt(s);

				System.out.println("Change the interval to:"+interval);

				serial.ChangeInterval(interval);
			}catch(IOException e){
				continue;
			}


		}

	}



}