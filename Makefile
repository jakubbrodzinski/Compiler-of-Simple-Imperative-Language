FLAGS=-std=c99 -Wall
BISON_FLAG=-D_BSD_SOURCE
all: compiler interpreter

compiler: bison.y flex.l
	bison -d bison.y -o bison.c
	flex -o flex.c flex.l
	gcc -o compiler bison.c flex.c $(FLAGS) $(BISON_FLAG) -lm -lfl
interpreter:
	g++ -Wall -std=c++11 interpreter.cc -o interpreter
	g++ -Wall -std=c++11 interpreter-cln.cc -l cln -o interpreter-cln
run:
	./compiler < ${SRC}
	./interpreter output;
runCLN:
	./compiler < ${SRC}
	./interpreter-cln output;
compile:
	./compiler < ${SRC}
exc:
	./interpreter output;
excCLN:
	./interpreter-cln output;
clean:
	rm bison.c bison.h flex.c compiler interpreter interpreter-cln output
