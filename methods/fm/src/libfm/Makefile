BIN_DIR := ../../bin/


OBJECTS := \
	libfm.o

libFM: $(OBJECTS)
	g++ -O3 $(OBJECTS) -o $(BIN_DIR)libFM

%.o: %.cpp
	g++ -O3 -Wall -c $< -o $@

clean:	clean_lib
	rm -f $(BIN_DIR)libFM

clean_lib:
	rm -f $(OBJECTS)

