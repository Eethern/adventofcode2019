CXX = g++
CXXFLAGS = -Wall -Wextra -std=c++14 -pedantic
LIBS = -lgtest -lgtest_main
SRC_DIR = src/
INCLUDE = include/
TARGET = bin/main

# Get a list of all .cpp files in the src/ directory
SRC := $(wildcard $(SRC_DIR)*.cpp)

all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(SRC) -I $(INCLUDE) $(LIBS)

run: $(TARGET)
	$(TARGET)

.PHONY: clean
clean:
	rm -f $(TARGET)
