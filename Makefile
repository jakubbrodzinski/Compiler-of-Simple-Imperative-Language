all: bison.y flex.l
		bison -d bison.y -o bison.c
		flex -o flex.c flex.l
		gcc -o compiler bison.c flex.c -lm -lfl
run:
	./compiler < ./myTest/test${NO}.imp
	./interpreter/interpreter output;
runBIG:
	./compiler < ./myTest/test${NO}.imp
	./interpreter/interpreter-cln output;
err:
	./compiler < ./test/error${NO}.imp
	./interpreter/interpreter output;			
clean:
	rm -f bison.c bison.h flex.c compiler
	
