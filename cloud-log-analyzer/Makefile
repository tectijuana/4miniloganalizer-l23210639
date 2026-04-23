AS = as
LD = ld
TARGET = analyzer

all: $(TARGET)

$(TARGET): analyzer.o
	$(LD) -o $(TARGET) analyzer.o

analyzer.o: src/analyzer.s
	$(AS) -o analyzer.o src/analyzer.s

clean:
	rm -f $(TARGET) *.o
