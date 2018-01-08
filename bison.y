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
VariableStack* getVariableByName(char * name);
#include "commandArray.c"
struct SingleCommand* getSingleCommandByIndex(int index);
struct SingleCommand* insertSingleCommand(int index,char* com,int a);
void construct(int s);
void cleanUp();
void writeIntoFile(char* filename);


int yyerror(char* error);
int yyerror2(int errNumber,char* varName);
int yylex();
void insertNumberIntoAccumulator(unsigned long long value);

int reg=0;
int lineNumber=0;

%}

%code requires{
    typedef struct ReturnStruct{
        char* varName;
        int isArray;
        int memAddress;
        int isDirect;
    }retVar;
}

%union{
    char* string;
    unsigned long long value;
    struct ReturnStruct retVar;
}

%token <string> VAR BEG END
%token <string> FOR FROM TO DOWNTO DO ENDFOR
%token <string> WHILE ENDWHILE
%token <string> IF THEN ELSE ENDIF
%token <string> READ WRITE
%token <string> ADD SUB MUL DIV MOD
%token <string> EQ NEQ LE GE LEQ GEQ AS LEFT RIGHT ENDL
%token <string> V
%token <value> NUMBER

%%
program         : VAR vdeclarations BEG commands END

vdeclarations   : vdeclarations V
                { 
                    printf("deklarcja zmiennej o nazwie %s\n",$<string>2);
                    if(insertNewVariable($<string>2,1,0,0)==-1){
                        yyerror2(6,$<string>2);
                    }
                }
                | vdeclarations V LEFT NUMBER RIGHT
                {
                    printf("deklarcja zmiennej o nazwie %s[%llu]\n",$<string>2,$<value>4);
                    if(insertNewVariable($<string>2,$<value>4,1,0)==-1){
                        yyerror2(6,$<string>2);
                    }
                    VariableStack* var=getVariableByName($<string>2);
                    insertNumberIntoAccumulator(var->memStart);
                    insertSingleCommand(lineNumber++,"STORE",var->memStart-1);
                }
                |
                ;

commands        : commands command
                | command
                ;

command         : identifier AS expression ENDL
                {
                    printf("command1.isDrect=%d\n",$<retVar>1.isDirect);
                    printf("command2.isDrect=%d\n",$<retVar>2.isDirect);
                    if($<retVar>3.varName !=NULL && strcmp($<retVar>3.varName,"ACC")!=0){
                        if($<retVar>3.isDirect==1){
                            insertSingleCommand(lineNumber++,"LOAD",$<retVar>3.memAddress);
                        }else{
                            insertSingleCommand(lineNumber++,"LOADI",$<retVar>3.memAddress);
                        }   
                    }
                    if($<retVar>1.isDirect==1){
                        insertSingleCommand(lineNumber++,"STORE",$<retVar>1.memAddress);
                        memoryArray[$<retVar>1.memAddress]=0;
                    }else{
                        insertSingleCommand(lineNumber++,"STOREI",$<retVar>1.memAddress);
                        //niech cała tablica bedzie 1 !!!!
                    }
                }
                | IF condition THEN commands ELSE commands ENDIF
                | IF condition THEN commands ENDIF
                | WHILE condition DO commands ENDWHILE
                | FOR V FROM value TO value DO commands ENDFOR
                | FOR V FROM value DOWNTO value DO commands ENDFOR
                | READ identifier ENDL
                {
                    insertSingleCommand(lineNumber++,"GET",-1);
                    if($<retVar>2.isDirect==1){
                        //co jesli to jest array!?
                        insertSingleCommand(lineNumber++,"STORE",$<retVar>2.memAddress);
                        memoryArray[$<retVar>2.memAddress]=0;
                    }else{
                        insertSingleCommand(lineNumber++,"STOREI",$<retVar>2.memAddress);
                    }
                }
                | WRITE value ENDL
                {
                    if($<retVar>2.isDirect==1){
                        //co jesli to jest array!?
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>2.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>2.memAddress);
                    }
                    insertSingleCommand(lineNumber++,"PUT",-1);
                }
                ;

expression      : value
                {
                    $<retVar>$.varName=$<retVar>1.varName;
                    $<retVar>$.isArray=$<retVar>1.isArray;
                    $<retVar>$.memAddress=$<retVar>1.memAddress;
                    $<retVar>$.isDirect=$<retVar>1.isDirect;
                    printf("exp1.isDrect=%d\n",$<retVar>1.isDirect);
                    printf("exp$.isDrect=%d\n",$<retVar>$.isDirect);
                }
                | value ADD value
                {
                    if($<retVar>1.isDirect==1){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>1.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>1.memAddress);
                    }
                    if($<retVar>3.isDirect==1){
                        //co jesli to jest array!?
                        insertSingleCommand(lineNumber++,"ADD",$<retVar>3.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"ADDI",$<retVar>3.memAddress);
                    }
                    $<retVar>$.varName="ACC";
                    
                }
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
                {
                    insertNumberIntoAccumulator($<value>1);
                    insertSingleCommand(lineNumber++,"STORE",reg);
                    $<retVar>$.varName=NULL;
                    $<retVar>$.isArray=0;
                    $<retVar>$.memAddress=reg;
                    $<retVar>$.isDirect=1;
                    printf("value.isDrect=%d\n",$<retVar>$.isDirect);
                    reg=(reg+1)%4;
                }
                | identifier
                {
                    $<retVar>$.varName=$<retVar>1.varName;
                    $<retVar>$.isArray=$<retVar>1.isArray;
                    $<retVar>$.memAddress=$<retVar>1.memAddress;
                    $<retVar>$.isDirect=$<retVar>1.isDirect;
                }
                ;

identifier      : V
                {
                    VariableStack* var=getVariableByName($<string>1);
                    //printf("%s-%d-%d-%d\n",var->varName,var->isArray,var->memStart,var->varSize);
                    if(var==NULL){
                        yyerror2(1,$<string>1);
                    }else if (var->isArray==1){
                        yyerror2(3,$<string>1);
                    }
                    $<retVar>$.varName=var->varName;
                    $<retVar>$.isArray=var->isArray;
                    $<retVar>$.memAddress=var->memStart;
                    $<retVar>$.isDirect=1;
                }
                | V LEFT V RIGHT
                {
                    VariableStack* var3=getVariableByName($<string>3);
                    if(var3==NULL){
                        yyerror2(1,$<string>1);
                    }else if (var3->isArray==1){
                        yyerror2(3,$<string>3);
                    }else if(memoryArray[var3->memStart]==-1){
                        yyerror2(2,$<string>3);
                    }
                    VariableStack* var1=getVariableByName($<string>1);
                    if(var1==NULL){
                        yyerror2(1,$<string>1);
                    }else if (var1->isArray==0){
                        yyerror2(3,$<string>1);
                    }
                    printf("%s-%d-%d-%d\n",var3->varName,var3->isArray,var3->memStart,var3->varSize);
                    insertSingleCommand(lineNumber++,"LOAD",var1->memStart-1);
                    insertSingleCommand(lineNumber++,"ADD",var3->memStart);
                    insertSingleCommand(lineNumber++,"STORE",reg);
                    $<retVar>$.varName=var1->varName;
                    $<retVar>$.isArray=var1->isArray;
                    $<retVar>$.memAddress=reg;
                    $<retVar>$.isDirect=0;
                    reg=(reg+1)%4;
                }
                | V LEFT NUMBER RIGHT
                {
                    VariableStack* var1=getVariableByName($<string>1);
                    if(var1==NULL){
                        yyerror2(1,$<string>1);
                    }else if (var1->isArray==0){
                        yyerror2(3,$<string>1);
                    }else if(var1->varSize <= $<value>3){
                        printf("varsize: %d\n",var1->varSize);
                        insertSingleCommand(lineNumber++,"HALT",-1);
                        writeIntoFile("outErr");
                        yyerror2(5,$<string>1);
                    }
                    $<retVar>$.varName=var1->varName;
                    $<retVar>$.isArray=var1->isArray;
                    $<retVar>$.memAddress=var1->memStart+$<value>3;
                    $<retVar>$.isDirect=1;
                }
                ;
%%

void insertNumberIntoAccumulator(unsigned long long value){
                    insertSingleCommand(lineNumber++,"ZERO",-1);
                    char number[64];
                    int i;
                    for(i=0;value!=0;i++){
                        if(value%2==1)
                            number[i]=1;
                        else
                            number[i]=0;
                        value/=2;
                    }
                    i--;
                    for(;i>0;i--){
                        if(number[i]==1){
                            insertSingleCommand(lineNumber++,"INC",-1);
                        }
                        insertSingleCommand(lineNumber++,"SHL",-1);
                    }
                    if(number[0]==1)
                        insertSingleCommand(lineNumber++,"INC",-1);
}

int main(){
    insertNewVariable("a1",1,0,0);
    insertNewVariable("a2",1,0,0);
    insertNewVariable("a3",1,0,0);
    insertNewVariable("a4",1,0,0);
    construct(1000);
    yyparse();
    for(int i=0;i<15;i++){
        //printf("%d: %s\n",i,getVariableFromMemory(i)->varName);
    }
    insertSingleCommand(lineNumber++,"HALT",-1);
    writeIntoFile("output");
    clearStack();
    cleanUp();
    free(memoryArray);
    return 0;
}
