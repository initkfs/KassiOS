/**
 * Authors: initkfs
 */
module os.std.date.systime;

import os.std.date.datetime;

private
{
    alias RTC = os.core.io.rtc;
}

LocalDate getDateUtc()
{
    RTC.DateTimeRtc dt = RTC.getDateTime;
    auto date = LocalDate(dt.year, dt.month, dt.day);
    return date;
}

LocalDateTime getDateTimeUtc()
{
    RTC.DateTimeRtc dt = RTC.getDateTime;
    auto date = LocalDateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
    return date;
}

