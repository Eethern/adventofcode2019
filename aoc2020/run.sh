#!/bin/bash

set -xe

CXXFLAGS="-Wall -Wextra -std=c++14 -pedantic"
LIBS="-lgtest -lgtest_main"
SRC="src/main.cpp src/problem.cpp
     src/day01.cpp
     src/day02.cpp
     src/day03.cpp
"
INCLUDE="include/"

g++ $CXXFLAGS -o bin/main $SRC -I $INCLUDE $LIBS

./bin/main
