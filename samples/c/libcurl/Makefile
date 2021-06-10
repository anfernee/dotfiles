CC := gcc
PROG := http-get

%.o: %.c
	$(CC) -c -o $@ $^ -lcurl

http-get: http-get.o
	$(CC) -o $@ $^ -lcurl

.PHONY: clean
clean:
	rm *.o ${PROG}