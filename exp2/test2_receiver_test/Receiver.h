// $Id: BlinkToRadio.h,v 1.4 2006/12/12 18:22:52 vlahan Exp $

#ifndef GOD_H
#define GOD_H

enum 
{
  AM_NUMBERMSG=0,
  AM_ACKMSG=5,
  AM_RESULTMSG=10,

  AM_REQMSG=91
};

typedef nx_struct NumberMsg 
{
  nx_uint16_t sequence_number;
  nx_uint32_t random_integer;
} NumberMsg;

typedef nx_struct AckMsg 
{
  nx_uint8_t group_id;
} AckMsg;

typedef nx_struct ResultMsg
{
  nx_uint8_t group_id;
  nx_uint32_t max;
  nx_uint32_t min;
  nx_uint32_t sum;
  nx_uint32_t average;
  nx_uint32_t median;
} ResultMsg;

typedef nx_struct ReqMsg
{
  nx_uint16_t magic;
  nx_uint32_t seqRequired;
} ReqMsg;

#define _MAGIC 0x2333

#define GROUP_ID 233

#endif
