
#include "parser.H"

#include <iostream>
using namespace std;

struct LOG_LINE
{
	string ipAddress;
	string date;
	string query;
	string referer;
	string userAgent;
	string cookie;
};

void separateFields(string& str, LOG_LINE& logLine)
{
	size_t i=0, j=0;

	// strip out IP address (no quotes or brackets)
	j = str.find_first_of(" ");
	if( j != string::npos )
	{
		logLine.ipAddress = str.substr(i, (j - i));
		i = j+1;
	}
	
	// strip out date (separated by brackets)
	j = str.find_first_of("]", i);
	if( j != string::npos )
	{
		logLine.date = str.substr(i+1, (j - i - 1));
		i = j+2;
	}
	
	// strip out query (escaped sequence)
	j = str.find_first_of(" ", i);
	if( j != string::npos )
	{
		logLine.query = str.substr(i, (j - i));
		i = j+1;
	}

	// strip out referer (escaped sequence)
	j = str.find_first_of(" ", i);
	if( j != string::npos )
	{
		logLine.referer = str.substr(i, (j - i));
		i = j+2;
	}

	// strip out user agent (quoted)
	j = str.find_first_of("\"", i);
	if( j != string::npos )
	{
		logLine.userAgent = str.substr(i, (j - i));
		i = j+2;
	}
}

time_t parseTime(string& str)
{
	tm time;

	size_t a=0, b=0;
	for( int i=0; i < 5; i++ )
	{
		b = str.find_first_of(" ", a);

		string sub = str.substr(a, (b-a));
		int element = atoi( sub.c_str() );

		switch( i )
		{
		case 0:  // Year
			time.tm_year = (element - 1900);
			break;
		case 1:  // Month
			time.tm_mon = (element - 1);
			break;
		case 2:  // Day of the month
			time.tm_mday = element;
			break;
		case 3:  // Hour
			time.tm_hour = element;
			break;
		case 4:  // Minutes
			time.tm_min = element;
			break;
		}

		a = b+1;
	}

	time.tm_sec = atoi( str.substr(a).c_str() ); // Seconds

	return mktime( &time );
}

bool parseRecord(string& string, LogRecord& record)
{
	LOG_LINE logLine;
	
	separateFields(string, logLine);
	record.time = parseTime(logLine.date);
	
	return true;
}