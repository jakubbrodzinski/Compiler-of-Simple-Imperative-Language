all: bison.y flex.l
		bison -d bison.y -o bison.c
		flex -o flex.c flex.l
		gcc -o compiler bison.c flex.c variableStack.c  -lm -lfl
		
clean:
	rm -f bison.c bison.h flex.c compiler
	
