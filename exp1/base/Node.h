// $Id: BlinkToRadio.h,v 1.4 2006/12/12 18:22:52 vlahan Exp $

#ifndef BLINKTORADIO_H
#define BLINKTORADIO_H

enum {
  AM_BLINKTORADIO = 99,
  AM_BLINKTORADIOMSG = 98,
  TIMER_PERIOD_MILLI = 250,
  SENDER = 0,
  MEDIATOR = 1,

  SENDER_MSG = 0,
  MEDIATOR_MSG = 1,
  CMD_MSG = 2,
  FORWARDED_MSG = 3
};

#define BUFFER_SIZE 150

typedef nx_struct BlinkToRadioMsg {
  nx_uint16_t msgType;
  nx_uint16_t msgNum;
  nx_uint32_t msgTime;

  nx_uint16_t temp;
  nx_uint16_t humid;
  nx_uint16_t light;

} BlinkToRadioMsg;

#endif
