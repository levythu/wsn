import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import java.util.ArrayList;
import java.util.Random;
import java.io.*;


class SerialUI extends JFrame {

	int totalCount;

	Serial serial;

	JTabbedPane topPanel;
	JPanel tempPanel;
	JPanel humidPanel;
	JPanel lightPanel;
	JPanel settingPanel;

	JLabel curFreqLabel;
	JLabel setFreqLabel;
	JLabel lossRateLabel;

	JLabel curFreqText;
	JTextField setFreqText;
	JLabel lossRateText;

	JButton settingButton;

	GraphDisplay tempDis;
	GraphDisplay humidDis;
	GraphDisplay lightDis;

	ArrayList<Double []> sendingNodeInfo;
	ArrayList<Double []> transferNodeInfo;
	
	MessageInfo info;
	public class MessageInfo {
		public int msgType;
		public int msgNum;
		public int msgTime;
		public double temp;
		public double humid;
		public double light;
	}

	SerialUI(Serial _serial) {
		int totalCount = 0;

		serial = _serial;
		serial.ChangeInterval(1000);

		info = new MessageInfo();
		
		sendingNodeInfo = new ArrayList<Double []>();
		transferNodeInfo = new ArrayList<Double []>();
		
		topPanel = new JTabbedPane();
		tempPanel = new JPanel();
		humidPanel = new JPanel();
		lightPanel = new JPanel();
		settingPanel = new JPanel();
		
		curFreqLabel = new JLabel("Current frequency:  ");
		setFreqLabel = new JLabel("   Set new frequency: ");
		lossRateLabel = new JLabel("   Loss rate:  ");
		
		curFreqText = new JLabel(" 1000   ");
		setFreqText = new JTextField(10);
		lossRateText = new JLabel(" %0.0  ");

		settingButton = new JButton("Set");
		
		this.setVisible(true);
		this.setLayout(new GridBagLayout());
		
		topPanel.addTab("TemperaturePanel", tempPanel);
		topPanel.setTitleAt(0, "Temperature");
		topPanel.setEnabled(true);
		topPanel.addTab("HumidityPanel", humidPanel);
		topPanel.setTitleAt(1, "Humidity");
		topPanel.setEnabled(true);
		topPanel.addTab("LightPanel", lightPanel);
		topPanel.setTitleAt(2, "Light");
		topPanel.setEnabled(true);
		topPanel.setPreferredSize(new Dimension(1000, 500));
		topPanel.setTabPlacement(JTabbedPane.TOP);
		topPanel.setTabLayoutPolicy(JTabbedPane.SCROLL_TAB_LAYOUT);
		topPanel.setVisible(true);
		this.add(topPanel, createTopGBC());
		
		tempDis = new GraphDisplay("temperature");
		tempDis.setSize(100, 100);
		tempPanel.setLayout(new GridBagLayout());
		tempPanel.add(tempDis, createGraphGBC());
		
		humidDis = new GraphDisplay("humidity");
		humidDis.setSize(100, 100);
		humidPanel.setLayout(new GridBagLayout());
		humidPanel.add(humidDis, createGraphGBC());
		
		lightDis = new GraphDisplay("light");
		lightDis.setSize(100, 100);
		lightPanel.setLayout(new GridBagLayout());
		lightPanel.add(lightDis, createGraphGBC());
		
		settingPanel.setLayout(new GridBagLayout());
		settingPanel.add(curFreqLabel);
		settingPanel.add(curFreqText);
		settingPanel.add(setFreqLabel);
		settingPanel.add(setFreqText);
		settingPanel.add(settingButton);
		settingButton.addActionListener(new HandleButtonClick(this));
		settingPanel.add(lossRateLabel);
		settingPanel.add(lossRateText);
		setFreqText.setVisible(true);
		setFreqText.setAutoscrolls(false);
		this.add(settingPanel, createSettingGBC());
		
		this.setSize(1000, 500);
		this.setTitle("WSN Experiment GUI");
	}

	public GridBagConstraints createTopGBC() {
		GridBagConstraints topGBC = new GridBagConstraints();
		topGBC.weightx = 100;
		topGBC.weighty = 100;
		topGBC.gridx = 0;
		topGBC.gridy = 0;
		topGBC.gridheight = 4;
		topGBC.gridwidth = 4;
		topGBC.fill = GridBagConstraints.BOTH;
		topGBC.anchor = GridBagConstraints.CENTER;
		return topGBC;
	}
	
	public GridBagConstraints createGraphGBC() {
		GridBagConstraints tempGBC = new GridBagConstraints();
		tempGBC = new GridBagConstraints();
		tempGBC.weightx = 100;
		tempGBC.weighty = 100;
		tempGBC.fill = GridBagConstraints.BOTH;
		tempGBC.gridheight = 1;
		tempGBC.gridwidth = 2;
		return tempGBC;
	}
	
	public GridBagConstraints createSettingGBC() {
		GridBagConstraints settingGBC = new GridBagConstraints();
		settingGBC.gridx = 0;
		settingGBC.gridy = 4;
		settingGBC.gridwidth = 4;
		settingGBC.gridheight = 1;
		settingGBC.fill = GridBagConstraints.BOTH;
		return settingGBC;
	}

	class GraphDisplay extends JPanel {
		
		int height, width;
		String type;

		GraphDisplay(String t) {
			this.setPreferredSize(new Dimension(200, 500));
			this.setVisible(true);
			this.type = t;
		}

		public void drawGraphics(Graphics g, ArrayList<Double []> list, Color color) {
			int[] xList = new int[list.size()];
			int[] yList = new int[list.size()];
			g.setColor(color);

			for (int i = 0; i < list.size(); i++) {
				double value;
				int base;
				if (this.type == "temperature") {
					value = list.get(i)[0];
					base = 100;
				} else if (this.type == "humidity") {
					value = list.get(i)[1];
					base = 300;
				} else {
					value = list.get(i)[2];
					base = 50;
				}
				double normalized_value = value / base * (height - 30);
				int x_value = i * 45 + 10, y_value = (height - 30) - (int)(normalized_value) + 10;
				g.drawOval(x_value - 3, y_value - 3, 6, 6);
				g.fillOval(x_value - 3, y_value - 3, 6, 6);
				xList[i] = x_value;
				yList[i] = y_value;
				String text = Double.toString(value);
				g.drawString(text, x_value - 10, y_value + 15);
			}

			for (int i = 0; i < list.size() - 1; i++) {
				int x_fir = xList[i], y_fir = yList[i];
				int x_sec = xList[i + 1], y_sec = yList[i + 1];
				g.drawLine(x_fir, y_fir, x_sec, y_sec);
			}
		}

		public void paint(Graphics g) {
			width = this.getWidth();
			height = this.getHeight();

			g.clearRect(0, 0, width, height);
			// g.setColor(Color.black);
			// g.fillRect(0, 0, width, height);

			g.setColor(Color.blue);
			g.drawString(this.type, 30, 30);
			g.drawLine(10, height - 20, width - 20, height - 20);
			g.drawLine(10, height - 20, 10, 10);

			g.drawLine(10, 10, 5, 15);
			g.drawLine(10, 10, 15, 15);
			g.drawLine(width - 20, height - 20, width - 25, height - 25);
			g.drawLine(width - 20, height - 20, width - 25, height - 15);

			for (int i = 1; i < 10; i++) {
				int y = (int)((double)(height - 30) / 10 * i + 10);
				g.drawLine(8, y, 12, y);
				int gap;
				if (this.type == "temperature") {
					gap = 10;
				} else if (this.type == "humidity") {
					gap = 30;
				} else {
					gap = 5;
				}
				g.drawString(Integer.toString((10 - i) * gap), 12, y);
			}

			drawGraphics(g, sendingNodeInfo, Color.orange);
			drawGraphics(g, transferNodeInfo, Color.red);
		}

	}
	
	class HandleButtonClick implements ActionListener {
		JFrame myFrame;
		HandleButtonClick(JFrame f) {
			myFrame = f;
		}
		public void actionPerformed(ActionEvent e) {
			try {
				if (e.getSource() == settingButton) {
					String freq = setFreqText.getText();
					int freqInt = Integer.parseInt(freq);
					System.out.println(freqInt);
					sendMessage(freqInt);
					curFreqText.setText(Integer.toString(freqInt));
				}
			} catch (Throwable exception) {
				System.err.println(exception);
			}
		}
	}
	
	public void sendMessage(int freqInt) {
		serial.ChangeInterval(freqInt);
	}
	
	public void adjustInfo(String str) {
		if (str == "sending") {
			sendingNodeInfo.remove(0);
		} else {
			transferNodeInfo.remove(0);
		}
	}

	public void addInfo(Serial.MessageInfo mInfo) {
		Double[] t = { 
			mInfo.temp, 
			mInfo.humid, 
			mInfo.light 
		};
		if (mInfo.msgType == 1) {
			sendingNodeInfo.add(t);
			if (sendingNodeInfo.size() > 20) {
				adjustInfo("sending");
			}
		} else if (mInfo.msgType == 3) {
			transferNodeInfo.add(t);
			if (transferNodeInfo.size() > 20) {
				adjustInfo("transfer");
			}
		}
	}
	
	public void updateLossRate(double newRate) {
		lossRateText.setText(String.format("%.2f", newRate));
	}

	public void updateInfo(Serial.MessageInfo mInfo) {
		System.out.println("GUI update begins!");

		mInfo.humid = Double.parseDouble(String.format("%.2f", mInfo.humid));
		mInfo.temp = Double.parseDouble(String.format("%.2f", mInfo.temp));
		mInfo.light = Double.parseDouble(String.format("%.2f", mInfo.light));

		long totalSeconds = mInfo.msgTime/10;
		long hour = totalSeconds/3600;
		long minute = totalSeconds%3600/60;
		long second = totalSeconds%3600%60;

		try {
			totalCount++;
			RandomAccessFile file = new RandomAccessFile("result.txt", "rw");
			long fileLength = file.length();
			file.seek(fileLength);
			file.writeBytes(Integer.toString(totalCount) + ' ' + mInfo.msgNum + ' ' + mInfo.temp + ' ' + mInfo.humid + ' ' + mInfo.light + ' ' + 
				hour+':'+minute+':'+second+ '\n');
			file.close();
		} catch (Throwable e) {
			System.err.println(e.toString());
		}

		addInfo(mInfo);
		tempDis.repaint();
		humidDis.repaint();
		lightDis.repaint();
		
		System.out.println("GUI update ends!");
	}
	
	/*
	public void work() {
		Random random = new Random(100);
		java.util.Timer timer = new java.util.Timer(true);
		java.util.TimerTask task = new java.util.TimerTask() {
			public void run() {
				MessageInfo t = new MessageInfo();
				t.msgType = random.nextInt() % 4;
				while (t.msgType != 0 && t.msgType != 3) {
					t.msgType = random.nextInt() % 4;
				}
				t.msgNum = 0;
				t.msgTime = 123;
				t.humid = random.nextDouble() * 120.0;
				t.humid = Double.parseDouble(String.format("%.2f", t.humid));
				t.temp = random.nextDouble() * 40.0;
				t.temp = Double.parseDouble(String.format("%.2f", t.temp));
				t.light = random.nextDouble() * 20.0 + 1.0;
				t.light = Double.parseDouble(String.format("%.2f", t.light));
				updateInfo(t);
				updateLossRate(random.nextDouble() * 10);
			}
		};
		timer.schedule(task, 0, 1000);
	}

	public static void main(String args[]) throws Throwable {
		SerialUI serialUI = new SerialUI();
		serialUI.work();
	}
	*/

}
