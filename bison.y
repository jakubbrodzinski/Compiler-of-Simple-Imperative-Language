%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

int* memoryArray;
#include "variableStack.c"

int isAlreadyDeclared(char * name);
int insertNewVariable(char * name,int size,int isArr,int isIterator);
int removeFromTop();
void clearStack();
VariableStack* getFromTop();
VariableStack* getVariableFromMemory(int memoryCell);
void yyerror(char * err);
int yylex();

%}

%union{
    char* string;
    unsigned long long value;
}

%token <string> VAR BEGIN END
%token <string> FOR FROM TO DOWNTO DO ENDFOR
%token <string> WHILE ENDWHILE
%token <string> IF THEN ELSE ENDIF
%token <string> READ WRITE
%token <string> ADD SUB MUL DIV MOD
%token <string> EQ NEQ LE GE LEQ GEQ AS LEFT RIGHT ENDL
%token <string> V
%token <value> NUMBER

%%
program         : VAR vdeclarations BEGIN commands END

vdeclarations   : vdeclarations V
                | vdeclarations V LEFT NUMBER RIGHT
                | 
                ;

commands        : commands command
                | command
                ;

command         : identifier AS expression ENDL
                | IF condition THEN commands ELSE commands ENDIF
                | IF condition THEN commands ENDIF
                | WHILE condition DO commands ENDWHILE
                | FOR V FROM value TO value DO commands ENDFOR
                | FOR V FROM value DOWNTO value DO commands ENDFOR
                | READ identifier ENDL
                | WRITE value ENDL
                ;

expression      : value
                | value ADD value
                | value SUB value
                | value MUL value
                | value DIV value
                | value MOD value
                ;

condition       : value EQ value
                | value NEQ value
                | value LE value
                | value GE value
                | value LEQ value
                | value GEQ value
                ;

value           : NUMBER
                | identifier
                ;

identifier      : V
                | V LEFT V RIGHT
                | V LEFT NUMBER RIGHT
                ;
%%

int main(){
    yyparse();
    clearStack();
    free(memoryArray);
    return 0;
}
