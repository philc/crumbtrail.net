#ifndef PARSER_H
#define PARSER_H

#include <string>
#include "logrecord.H"

bool parseRecord(std::string& line, LogRecord& record);

#endif