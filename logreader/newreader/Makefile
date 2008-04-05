CC=g++
CFLAGS=-c -Wall
LFLAGS=-Wall
TARGET=logreader
SRC=logreader.cpp logrecord.cpp parser.cpp

OBJ = $(SRC:.cpp=.o)

$(TARGET): $(OBJ)
	$(CC) $(LFLAGS) -o $@ $(OBJ)

.cpp.o:
	$(CC) $(CFLAGS) -o $@ $*.cpp

clean:
	-rm *.o *~ core logreader
	
depend:
	makedepend -Y -- $(CFLAGS) -- $(SRC)

# DO NOT DELETE THIS LINE -- make depend depends on it.

logreader.o: parser.H logrecord.H
logrecord.o: logrecord.H
parser.o: parser.H logrecord.H
