CFLAGS ?= -Wall -O2

all: check_python

check_python: python.c
	$(CC) $(CFLAGS) -o check_python python.c

clean:
	rm -f check_python
