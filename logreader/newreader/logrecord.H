#ifndef LOGRECORD_H
#define LOGRECORD_H

#include <string>

using namespace std;

#define INVALID_TIME 0
#define TIME_NOT_SET 1
#define NOT_SET      -1

struct LogRecord
{
	string ipAddress;
	int    project;
	time_t time;
};

void clearLogRecord(LogRecord& logrecord);


#endif