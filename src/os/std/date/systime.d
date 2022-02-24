/**
 * Authors: initkfs
 */
module os.std.date.systime;

import os.std.date.datetime;

import RTC = os.core.io.rtc;

void getDateUtc(out LocalDate localDate)
{
    RTC.DateTimeRtc dt;
    RTC.getDateTime(dt);
    localDate.year = dt.year;
    localDate.month = dt.month;
    localDate.day = dt.day;
}

void getDateTimeUtc(out LocalDateTime localDatetime)
{
    RTC.DateTimeRtc dt;
    RTC.getDateTime(dt);
    //TODO auto copy
    localDatetime.year = dt.year;
    localDatetime.month = dt.month;
    localDatetime.hour = dt.hour;
    localDatetime.minute = dt.minute;
    localDatetime.second = dt.second;
}
