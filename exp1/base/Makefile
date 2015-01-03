COMPONENT = BaseC
BUILD_EXTRA_DEPS += Serial.class
CLEAN_EXTRA = *.class SerialMsg.java

CFLAGS += -I$(TOSDIR)/lib/T2Hack
CFLAGS += -DCC2420_DEF_CHANNEL=22

Serial.class: $(wildcard *.java) SerialMsg.java
	javac -target 1.5 -source 1.5 *.java

SerialMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=SerialMsg Node.h BlinkToRadioMsg -o $@


include $(MAKERULES)

