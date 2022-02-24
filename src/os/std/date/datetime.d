/**
 * Authors: initkfs
 */
module os.std.date.datetime;

import Strings = os.std.text.strings;

struct LocalDate
{
    const
    {
        int year;
        int month;
        int day;
    }
}

struct LocalDateTime
{
    const
    {
        int year;
        int month;
        int day;
        int hour;
        int minute;
        int second;
    }
}

enum DayOfWeek
{
    Sunday,
    Monday,
    Tuesday,
    Wednesday,
    Thursday,
    Friday,
    Saturday
}

enum MonthOfYear
{
    January,
    February,
    March,
    April,
    May,
    June,
    July,
    August,
    September,
    October,
    November,
    December
}

char* toIsoSimpleString(LocalDate date)
{
    uint[3] dtInfo = [date.year, date.month, date.day];
    auto dateInfo = Strings.format("%0d-%0d-%0d", dtInfo);
    return dateInfo;
}

char* toIsoSimpleString(LocalDateTime date)
{
    int[6] dtInfo = [
        date.year, date.month, date.day, date.hour, date.minute, date.second
    ];
    char* dateInfo = Strings.format("%0d-%0d-%0d %0d:%0d:%0d", dtInfo);
    return dateInfo;
}
