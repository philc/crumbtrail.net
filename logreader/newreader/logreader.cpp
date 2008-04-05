#include <stdio.h>
#include <GetOpt.h>
#include <iostream>
#include <string>
#include <fstream>

#include "parser.H"
#include "logrecord.H"

using namespace std;

void printUsage()
{
	cout << "usage: logreader" << endl;
}

int main( int argc, char **argv )
{
	int option_char;
	
	char* filename = NULL;
	
	while( (option_char = getopt(argc, argv, "hf:")) != EOF )
	{
		switch( option_char )
		{
			case 'f': filename = optarg; break;
			case 'h': printUsage(); return 1; break;
			case '?': printUsage(); break;
		}
	}

	int totalLines = 0;
	
	ifstream in(filename);
	if( !in )
	{
		cerr << "No log file name specified\n";
		return 1;
	}
	
	LogRecord record;
	string lineIn;
	while( in )
	{
		getline(in, lineIn);
		if( parseRecord(lineIn, record) )
		{
			
		}
		
		totalLines++;
	}

	in.close();

	cout << "Processed " << totalLines << " lines.";

	return 0;
}