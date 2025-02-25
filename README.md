Compiler of simple imperative language. 
1.Language's grammar:

    program -> VAR vdeclarations BEGIN commands END

    vdeclarations -> vdeclarations pidentifier
        | vdeclarations pidentifier [num]
        | /*epsilon*/

    commands -> commands command
        | command

    command -> identifier := expression ;
        | IF condition THEN commands ELSE commands ENDIF
        | IF condition THEN commands ENDIF
        | WHILE condition DO commands ENDWHILE
        | FOR pidentifier FROM value TO value DO commands ENDFOR
        | FOR pidentifier FROM value DOWNTO value DO commands ENDFOR
        | READ identifier ;
        | WRITE value ;

    expression -> value
        | value + value
        | value - value
        | value * value
        | value / value
        | value % value

    condition -> value = value
        | value <> value
        | value < value
        | value > value
        | value <= value
        | value >= value

    value -> num
        | identifier

    identifier -> pidentifier
        | pidentifier [ pidentifier ]
        | pidentifier [num]
 
 
2.Project's files:

	-bison.y
        Parser
	-flex.l
        Lexer
	-commandArray.c
        Data structure where asembler's commands are stored.
	-jumpStack.c
        Simple stack that is used to implementing jumps in compiler, that are used in loops, branches (if/else).
	-variableStack.c
        Linked list that stored declared variables and their's addresses.
	-interpreter.cc
	-interpreter-cln.cc
	-Makefile

Versions:

	flex 2.6.0
	bison (GNU Bison) 3.0.4
	gcc (Ubuntu 5.4.0-6ubuntu1~16.04.5) 5.4.0 20160609

Build and run:

    To build whole project use 'make' or 'make compiler' to build ONLY compiler (without interpreter). To build interpreter use 'make interpreter'.
	
	To compile and run your code use command:
		'make run SRC=path'
	or for CLN interpreter:
		'make runCLN SRC=path'
	where 'path' is path to text file with code.

	Output of the compiler (assembler) is always in the file named 'output' in compilers' directory.

	To only compile code (without executing it) use:
		'make compile SRC=path'

	To execute assembler from file named 'output' use:
		'make exc'
	or with interpreter CLN:
		'make excCLN'

	'make clean' removes all temporary and built files.
	
Additional info:
	
    During compiling my simple compiler you can get some warnings. Thoose warnings are effect of using gcc and ANSI C instead of g++ and C++. Evertyhing works just fine.
	
