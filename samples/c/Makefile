TARGET=align
CC=gcc  # or clang

all: $(TARGET)

$(TARGET): %: %.c
	$(CC) $@.c -o $@

clean:
	rm -rf $(TARGET)
