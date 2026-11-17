# Host tests for the AmigaOS pieces: make test
CXX ?= c++
CXXFLAGS ?= -std=c++20 -Wall -Wextra -Werror -O1
test: test_mutex
	./test_mutex
	sh test-sources.sh
	sh test-part.sh
test_mutex: test_mutex.cpp ../compat/gbt_amiga_mutex.h
	$(CXX) $(CXXFLAGS) -I../compat -pthread -o $@ test_mutex.cpp
clean:
	rm -f test_mutex
.PHONY: test clean
