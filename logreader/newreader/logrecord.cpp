#include "logrecord.H"

void clearLogRecord(LogRecord& logRecord)
{
	logRecord.project   = NOT_SET;
	logRecord.ipAddress = "";
	logRecord.time      = TIME_NOT_SET;
}