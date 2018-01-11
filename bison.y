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
int insertLoopRange(int loopC);
#include "commandArray.c"
struct SingleCommand* getSingleCommandByIndex(int index);
struct SingleCommand* insertSingleCommand(int index,char* com,int a);
void construct(int s);
void cleanUp();
void writeIntoFile(char* filename);

#include "jumpStack.c"
void pushJump(int lineN);
void cleanJumpStack();
int popJump();

int yyerror(char* error);
int yyerror2(int errNumber,char* varName);
void freeStructures();
int yylex();
void insertNumberIntoAccumulator(unsigned long long value);

int reg=0;  //ktory aktualnie rejestr uzyć. mod 4
int regMax=10;
int lineNumber=0;
int loopCounter=0; // ktora to jest petla, tylko i wylacnzie do nazywania zmiennych na stosie
int inWhileLoop=0; // inne zachowanie condition jezeli jest rowne 1
int numberLoaded=0; // do while'a, jezeli warunek zawiera "szytwna" liczbe to wrzucamy ja na stack'a z variableStack

extern int stackPointer;

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
                    if(insertNewVariable($<string>2,1,0,0)==-1){
                        yyerror2(6,$<string>2);
                    }
                }
                | vdeclarations V LEFT NUMBER RIGHT
                {
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
                    VariableStack* var=getVariableByName($<retVar>1.varName);
                    if(var->varType==1){
                        yyerror2(9,$<retVar>1.varName);
                    }
                    if($<retVar>3.varName !=NULL && strcmp($<retVar>3.varName,"ACC")!=0){
                        if($<retVar>3.isDirect==1){
                            insertSingleCommand(lineNumber++,"LOAD",$<retVar>3.memAddress);
                        }else{
                            insertSingleCommand(lineNumber++,"LOADI",$<retVar>3.memAddress);
                        }   
                    }else{
                        $<retVar>3.varName=NULL;
                    }
                    if($<retVar>1.isDirect==1){
                        insertSingleCommand(lineNumber++,"STORE",$<retVar>1.memAddress);
                        memoryArray[$<retVar>1.memAddress]=0;
                    }else{
                        insertSingleCommand(lineNumber++,"STOREI",$<retVar>1.memAddress);
                        //niech cała tablica bedzie 1 !!!!
                        printf("name: %s\n size: %d\n memStart:%d\n",var->varName,var->varSize,var->memStart);
                        for(int i=0;i<var->varSize;i++){
                            memoryArray[var->memStart+i]=0;
                        }
                    }
                }
                | IF 
                condition 
                {
                    pushJump(lineNumber);
                    insertSingleCommand(lineNumber++,"JZERO",-1);
                }
                THEN comm_gram
                | WHILE 
                {
                    inWhileLoop=1;

                }
                condition 
                {
                    pushJump(lineNumber);
                    pushJump(numberLoaded);
                    insertSingleCommand(lineNumber++,"JZERO",-1);
                    inWhileLoop=0;
                    numberLoaded=0;
                }
                DO commands ENDWHILE
                {
                    int numberL=popJump();
                    int afterCond=popJump();
                    int beforeCond=popJump();
                    insertSingleCommand(lineNumber++,"JUMP",beforeCond);
                    getSingleCommandByIndex(afterCond)->arg=lineNumber;
                    while(numberL>0){
                        if(removeFromTop()==-1){
                            printf("PROBLEM Z WHILE!!!\n");
                        }
                        numberL--;
                    }
                }
                | FOR V FROM value TO value 
                {
                    if($<retVar>4.isDirect==1){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>4.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>4.memAddress);
                    }
                    if($<retVar>6.isDirect==1){
                        //co jesli to jest array!?
                        insertSingleCommand(lineNumber++,"SUB",$<retVar>6.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"SUBI",$<retVar>6.memAddress);
                    }
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+3); // zmiana
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"ZERO",-1);
                    insertSingleCommand(lineNumber,"JUMP",lineNumber+7);    //zmiana
                    lineNumber++;
                    
                    if($<retVar>4.isDirect==1){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>4.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>4.memAddress);
                    }
                    
                    if(insertNewVariable($<string>2,1,0,1)==-1){
                        yyerror2(6,$<string>2);
                    }
                    insertSingleCommand(lineNumber++,"STORE",stackPointer-1);
                    memoryArray[stackPointer-1]=0;

                    if($<retVar>6.isDirect==1){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>6.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>6.memAddress);
                    }
                    if($<retVar>4.isDirect==1){
                        //co jesli to jest array!?
                        insertSingleCommand(lineNumber++,"SUB",$<retVar>4.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"SUBI",$<retVar>4.memAddress);
                    }
                    insertSingleCommand(lineNumber++,"INC",-1);
                    
                    loopCounter++;
                    insertLoopRange(loopCounter);
                    insertSingleCommand(lineNumber++,"STORE",stackPointer-1);
                    memoryArray[stackPointer-1]=0;
                    pushJump(lineNumber);
                    insertSingleCommand(lineNumber++,"JZERO",-2);
                }
                DO commands ENDFOR
                {
                    insertSingleCommand(lineNumber++,"LOAD",stackPointer-2); //load iterator
                    insertSingleCommand(lineNumber++,"INC",-1);
                    insertSingleCommand(lineNumber++,"STORE",stackPointer-2);//save iterator
                    insertSingleCommand(lineNumber++,"LOAD",stackPointer-1); //load RANGE
                    insertSingleCommand(lineNumber++,"DEC",-1);
                    insertSingleCommand(lineNumber++,"STORE",stackPointer-1);//save RANGE
                    int jumpLine=popJump();
                    insertSingleCommand(lineNumber++,"JUMP",jumpLine);
                    struct SingleCommand* lastJzero=getSingleCommandByIndex(jumpLine);
                    lastJzero->arg=lineNumber;
                    removeFromTop();
                    removeFromTop();
                    
                }
                | FOR V FROM value DOWNTO value 
                {
                    if($<retVar>6.isDirect==1){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>6.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>6.memAddress);
                    }
                    if($<retVar>4.isDirect==1){
                        //co jesli to jest array!?
                        insertSingleCommand(lineNumber++,"SUB",$<retVar>4.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"SUBI",$<retVar>4.memAddress);
                    }
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+3); // zmiana
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"ZERO",-1);
                    insertSingleCommand(lineNumber,"JUMP",lineNumber+5);    //zmiana
                    lineNumber++;
                    
                    if($<retVar>4.isDirect==1){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>4.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>4.memAddress);
                    }
                    
                    if(insertNewVariable($<string>2,1,0,1)==-1){
                        yyerror2(6,$<string>2);
                    }
                    insertSingleCommand(lineNumber++,"STORE",stackPointer-1);
                    memoryArray[stackPointer-1]=0;

                    if($<retVar>6.isDirect==1){
                        //co jesli to jest array!?
                        insertSingleCommand(lineNumber++,"SUB",$<retVar>6.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"SUBI",$<retVar>6.memAddress);
                    }
                    insertSingleCommand(lineNumber++,"INC",-1);
                    //TO-DO!!! zrobic jakis glupi licznik
                    loopCounter++;
                    insertLoopRange(loopCounter);
                    insertSingleCommand(lineNumber++,"STORE",stackPointer-1);
                    memoryArray[stackPointer-1]=0;
                    pushJump(lineNumber);
                    insertSingleCommand(lineNumber++,"JZERO",-2);
                }
                DO commands ENDFOR
                {
                    insertSingleCommand(lineNumber++,"LOAD",stackPointer-2); //load iterator
                    insertSingleCommand(lineNumber++,"DEC",-1);
                    insertSingleCommand(lineNumber++,"STORE",stackPointer-2);//save iterator
                    insertSingleCommand(lineNumber++,"LOAD",stackPointer-1); //load RANGE
                    insertSingleCommand(lineNumber++,"DEC",-1);
                    insertSingleCommand(lineNumber++,"STORE",stackPointer-1);//save RANGE
                    int jumpLine=popJump();
                    insertSingleCommand(lineNumber++,"JUMP",jumpLine);
                    struct SingleCommand* lastJzero=getSingleCommandByIndex(jumpLine);
                    lastJzero->arg=lineNumber;
                    removeFromTop();
                    removeFromTop();
                }
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
comm_gram       : commands 
                {
                    int ifJump=popJump();
                    struct SingleCommand* jZero=getSingleCommandByIndex(ifJump);
                    jZero->arg=lineNumber;
                }
                ENDIF 
                | commands {
                    int ifJump=popJump();
                    pushJump(lineNumber);
                    insertSingleCommand(lineNumber++,"JUMP",-1);
                    struct SingleCommand* jZero=getSingleCommandByIndex(ifJump);
                    jZero->arg=lineNumber;
                }
                ELSE 
                commands ENDIF
                {
                    int elseJump=popJump();
                    struct SingleCommand* elseCommand=getSingleCommandByIndex(elseJump);
                    elseCommand->arg=lineNumber;
                }
                ;

expression      : value
                {
                    $<retVar>$.varName=$<retVar>1.varName;
                    $<retVar>$.isArray=$<retVar>1.isArray;
                    $<retVar>$.memAddress=$<retVar>1.memAddress;
                    $<retVar>$.isDirect=$<retVar>1.isDirect;
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
                {
                    if($<retVar>1.isDirect==1){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>1.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>1.memAddress);
                    }
                    if($<retVar>3.isDirect==1){
                        //co jesli to jest array!?
                        insertSingleCommand(lineNumber++,"SUB",$<retVar>3.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"SUBI",$<retVar>3.memAddress);
                    }
                    $<retVar>$.varName="ACC";
                }
                | value MUL value
                {
                    int left=-1;
                    if($<retVar>1.isDirect==0){
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>1.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",reg);
                        left=reg;
                        reg=(reg+1)%regMax;
                    }else if(strcmp($<retVar>1.varName,"REG")!=0){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>1.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",reg);
                        left=reg;
                        reg=(reg+1)%regMax;
                    }else{
                        left=$<retVar>1.memAddress;
                    }
                    //lewą zmienna mamy w rejestrze LEFT
                    int right=-1;
                    if($<retVar>3.isDirect==0){
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>3.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",reg);
                        right=reg;
                        reg=(reg+1)%regMax;
                    }else if(strcmp($<retVar>3.varName,"REG")!=0){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>3.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",reg);
                        right=reg;
                        reg=(reg+1)%regMax;
                    }else{
                        right=$<retVar>3.memAddress;
                    }
                    //prawą zmienna mamy w rejestrze RIGHT
                    int regStore=reg;
                    reg=(reg+1)%regMax;
                    insertSingleCommand(lineNumber++,"ZERO",-1);
                    insertSingleCommand(lineNumber++,"STORE",regStore);
                    insertSingleCommand(lineNumber++,"LOAD",right);
                    insertSingleCommand(lineNumber++,"SUB",left);
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+17);//TO_DO do 425
                    lineNumber++;
                    //LEFT < RIGHT
                    insertSingleCommand(lineNumber++,"LOAD",left);
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+14);  //do 422
                    lineNumber++;
                    insertSingleCommand(lineNumber,"JODD",lineNumber+4);    //do 413
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"SHR",-1);
                    insertSingleCommand(lineNumber++,"STORE",left);
                    insertSingleCommand(lineNumber,"JUMP",lineNumber+6);    //do 418
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"SHR",-1);
                    insertSingleCommand(lineNumber++,"STORE",left);
                    insertSingleCommand(lineNumber++,"LOAD",regStore);
                    insertSingleCommand(lineNumber++,"ADD",right);
                    insertSingleCommand(lineNumber++,"STORE",regStore);
                    insertSingleCommand(lineNumber++,"LOAD",right);
                    insertSingleCommand(lineNumber++,"SHL",-1);
                    insertSingleCommand(lineNumber++,"STORE",right);
                    insertSingleCommand(lineNumber,"JUMP",lineNumber-14);   //do 404
                    lineNumber++;
                    insertSingleCommand(lineNumber,"JUMP",lineNumber+16);//za 442
                    lineNumber++;
                    //LEFT >=RIGHT
                    insertSingleCommand(lineNumber++,"LOAD",right);
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+14);      //za 442
                    lineNumber++;
                    insertSingleCommand(lineNumber,"JODD",lineNumber+4);        //434
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"SHR",-1);
                    insertSingleCommand(lineNumber++,"STORE",right);
                    insertSingleCommand(lineNumber,"JUMP",lineNumber+6);        //do 439
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"SHR",-1);
                    insertSingleCommand(lineNumber++,"STORE",right);
                    insertSingleCommand(lineNumber++,"LOAD",regStore);
                    insertSingleCommand(lineNumber++,"ADD",left);
                    insertSingleCommand(lineNumber++,"STORE",regStore);
                    insertSingleCommand(lineNumber++,"LOAD",left);
                    insertSingleCommand(lineNumber++,"SHL",-1);
                    insertSingleCommand(lineNumber++,"STORE",left);
                    insertSingleCommand(lineNumber,"JUMP",lineNumber-14);       //do 425
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"LOAD",regStore);
                    $<retVar>$.varName="ACC";
                    
                }
                | value DIV value     //LEFT / RIGHT
                {
                    int right=-1;
                    if($<retVar>3.isDirect==0){
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>3.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",reg);
                        right=reg;
                        reg=(reg+1)%regMax;
                    }else if(strcmp($<retVar>3.varName,"REG")!=0){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>3.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",reg);
                        right=reg;
                        reg=(reg+1)%regMax;
                    }else{
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>3.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",reg);
                        right=reg;
                        reg=(reg+1)%regMax;
                    }
                    //prawą zmienna mamy w rejestrze RIGHT
                    
                    pushJump(lineNumber);
                    insertSingleCommand(lineNumber,"JZERO",-1);
                    lineNumber++;
                    
                    int left=-1;
                    if($<retVar>1.isDirect==0){
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>1.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",reg);
                        left=reg;
                        reg=(reg+1)%regMax;
                    }else if(strcmp($<retVar>1.varName,"REG")!=0){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>1.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",reg);
                        left=reg;
                        reg=(reg+1)%regMax;
                    }else{
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>1.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",reg);
                        left=reg;
                        reg=(reg+1)%regMax;
                    }
                    //lewą zmienna mamy w rejestrze LEFT
                    
                    pushJump(lineNumber);
                    insertSingleCommand(lineNumber,"JZERO",-1);
                    lineNumber++;
                    
                    int regStore=reg;
                    reg=(reg+1)%regMax;
                    
                    insertSingleCommand(lineNumber++,"ZERO",-1);
                    insertSingleCommand(lineNumber++,"INC",-1);
                    insertSingleCommand(lineNumber++,"STORE",regStore);
                    insertSingleCommand(lineNumber++,"LOAD",left);
                    insertSingleCommand(lineNumber++,"SHR",-1);
                    insertSingleCommand(lineNumber++,"STORE",left);
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+5);
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"LOAD",regStore);
                    insertSingleCommand(lineNumber++,"INC",-1);
                    insertSingleCommand(lineNumber++,"STORE",regStore);
                    insertSingleCommand(lineNumber,"JUMP",lineNumber-7);
                    lineNumber++;

                    insertSingleCommand(lineNumber++,"LOAD",regStore);
                    insertSingleCommand(lineNumber++,"DEC",-1);
                    insertSingleCommand(lineNumber++,"STORE",regStore);
                    insertSingleCommand(lineNumber++,"LOAD",right);
                    insertSingleCommand(lineNumber++,"SHR",-1);
                    insertSingleCommand(lineNumber++,"STORE",right);
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+5);
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"LOAD",regStore);
                    insertSingleCommand(lineNumber++,"DEC",-1);
                    insertSingleCommand(lineNumber++,"STORE",regStore);
                    insertSingleCommand(lineNumber,"JUMP",lineNumber-7);
                    lineNumber++;

                    if($<retVar>1.isDirect==0){
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>1.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",left);
                    }else if(strcmp($<retVar>1.varName,"REG")!=0){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>1.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",left);
                    }else{
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>1.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",left);
                    }
                    //lewą zmienna mamy w rejestrze LEFT
                    if($<retVar>3.isDirect==0){
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>3.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",right);
                    }else if(strcmp($<retVar>3.varName,"REG")!=0){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>3.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",right);
                    }else{
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>3.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",right);
                    }

                    //left-dividend     right-divisor
                    insertSingleCommand(lineNumber++,"LOAD",regStore);
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+7);
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"DEC",-1);
                    insertSingleCommand(lineNumber++,"STORE",regStore);
                    insertSingleCommand(lineNumber++,"LOAD",right);
                    insertSingleCommand(lineNumber++,"SHL",-1);
                    insertSingleCommand(lineNumber++,"STORE",right);
                    insertSingleCommand(lineNumber,"JUMP",lineNumber-7);
                    lineNumber++;

                    //main LOOP!! WHILE right >= <retVar>3.memAddress
                    //DO POPRWAY!! Z IFEM
                    if($<retVar>3.isDirect==1){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>3.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>3.memAddress);
                    }
                    insertSingleCommand(lineNumber++,"SUB",right);
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+2);
                    lineNumber++;
                    //FALSE - wyskakuj zpetli
                    insertSingleCommand(lineNumber,"JUMP",lineNumber+19);
                    lineNumber++;
                    //TRUE -odejmij,sprwadz,zmniejsz right
                    //if left >= right
                    insertSingleCommand(lineNumber++,"LOAD",right);
                    insertSingleCommand(lineNumber++,"SUB",left);
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+5);
                    lineNumber++;//else
                    insertSingleCommand(lineNumber++,"LOAD",regStore);
                    insertSingleCommand(lineNumber++,"SHL",-1);
                    insertSingleCommand(lineNumber++,"STORE",regStore);
                    insertSingleCommand(lineNumber,"JUMP",lineNumber+8);
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"LOAD",left);
                    insertSingleCommand(lineNumber++,"SUB",right);
                    insertSingleCommand(lineNumber++,"STORE",left);
                    insertSingleCommand(lineNumber++,"LOAD",regStore);
                    insertSingleCommand(lineNumber++,"SHL",-1); // !!!!
                    insertSingleCommand(lineNumber++,"INC",-1); // !!!!
                    insertSingleCommand(lineNumber++,"STORE",regStore);
                    
                    insertSingleCommand(lineNumber++,"LOAD",right);
                    insertSingleCommand(lineNumber++,"SHR",-1);
                    insertSingleCommand(lineNumber++,"STORE",right);
                    insertSingleCommand(lineNumber,"JUMP",lineNumber-21);
                    lineNumber++;

                    insertSingleCommand(lineNumber++,"LOAD",regStore);
                    $<retVar>$.varName="ACC";
                    int jzeroJumper=popJump();
                    getSingleCommandByIndex(jzeroJumper)->arg=lineNumber;
                    jzeroJumper=popJump();
                    getSingleCommandByIndex(jzeroJumper)->arg=lineNumber;
                }
                | value MOD value
                                {
                    int right=-1;
                    if($<retVar>3.isDirect==0){
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>3.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",reg);
                        right=reg;
                        reg=(reg+1)%regMax;
                    }else if(strcmp($<retVar>3.varName,"REG")!=0){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>3.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",reg);
                        right=reg;
                        reg=(reg+1)%regMax;
                    }else{
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>3.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",reg);
                        right=reg;
                        reg=(reg+1)%regMax;
                    }
                    //prawą zmienna mamy w rejestrze RIGHT
                    
                    pushJump(lineNumber);
                    insertSingleCommand(lineNumber,"JZERO",-1);
                    lineNumber++;
                    
                    int left=-1;
                    if($<retVar>1.isDirect==0){
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>1.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",reg);
                        left=reg;
                        reg=(reg+1)%regMax;
                    }else if(strcmp($<retVar>1.varName,"REG")!=0){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>1.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",reg);
                        left=reg;
                        reg=(reg+1)%regMax;
                    }else{
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>1.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",reg);
                        left=reg;
                        reg=(reg+1)%regMax;
                    }
                    //lewą zmienna mamy w rejestrze LEFT
                    
                    pushJump(lineNumber);
                    insertSingleCommand(lineNumber,"JZERO",-1);
                    lineNumber++;
                    
                    int regStore=reg;
                    reg=(reg+1)%regMax;
                    
                    insertSingleCommand(lineNumber++,"ZERO",-1);
                    insertSingleCommand(lineNumber++,"INC",-1);
                    insertSingleCommand(lineNumber++,"STORE",regStore);
                    insertSingleCommand(lineNumber++,"LOAD",left);
                    insertSingleCommand(lineNumber++,"SHR",-1);
                    insertSingleCommand(lineNumber++,"STORE",left);
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+5);
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"LOAD",regStore);
                    insertSingleCommand(lineNumber++,"INC",-1);
                    insertSingleCommand(lineNumber++,"STORE",regStore);
                    insertSingleCommand(lineNumber,"JUMP",lineNumber-7);
                    lineNumber++;

                    insertSingleCommand(lineNumber++,"LOAD",regStore);
                    insertSingleCommand(lineNumber++,"DEC",-1);
                    insertSingleCommand(lineNumber++,"STORE",regStore);
                    insertSingleCommand(lineNumber++,"LOAD",right);
                    insertSingleCommand(lineNumber++,"SHR",-1);
                    insertSingleCommand(lineNumber++,"STORE",right);
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+5);
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"LOAD",regStore);
                    insertSingleCommand(lineNumber++,"DEC",-1);
                    insertSingleCommand(lineNumber++,"STORE",regStore);
                    insertSingleCommand(lineNumber,"JUMP",lineNumber-7);
                    lineNumber++;

                    if($<retVar>1.isDirect==0){
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>1.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",left);
                    }else if(strcmp($<retVar>1.varName,"REG")!=0){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>1.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",left);
                    }else{
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>1.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",left);
                    }
                    //lewą zmienna mamy w rejestrze LEFT
                    if($<retVar>3.isDirect==0){
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>3.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",right);
                    }else if(strcmp($<retVar>3.varName,"REG")!=0){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>3.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",right);
                    }else{
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>3.memAddress);
                        insertSingleCommand(lineNumber++,"STORE",right);
                    }

                    //left-dividend     right-divisor
                    insertSingleCommand(lineNumber++,"LOAD",regStore);
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+7);
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"DEC",-1);
                    insertSingleCommand(lineNumber++,"STORE",regStore);
                    insertSingleCommand(lineNumber++,"LOAD",right);
                    insertSingleCommand(lineNumber++,"SHL",-1);
                    insertSingleCommand(lineNumber++,"STORE",right);
                    insertSingleCommand(lineNumber,"JUMP",lineNumber-7);
                    lineNumber++;

                    //main LOOP!! WHILE right >= <retVar>3.memAddress
                    //DO POPRWAY!! Z IFEM
                    if($<retVar>3.isDirect==1){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>3.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>3.memAddress);
                    }
                    insertSingleCommand(lineNumber++,"SUB",right);
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+2);
                    lineNumber++;
                    //FALSE - wyskakuj zpetli
                    insertSingleCommand(lineNumber,"JUMP",lineNumber+19);
                    lineNumber++;
                    //TRUE -odejmij,sprwadz,zmniejsz right
                    //if left >= right
                    insertSingleCommand(lineNumber++,"LOAD",right);
                    insertSingleCommand(lineNumber++,"SUB",left);
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+5);
                    lineNumber++;//else
                    insertSingleCommand(lineNumber++,"LOAD",regStore);
                    insertSingleCommand(lineNumber++,"SHL",-1);
                    insertSingleCommand(lineNumber++,"STORE",regStore);
                    insertSingleCommand(lineNumber,"JUMP",lineNumber+8);
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"LOAD",left);
                    insertSingleCommand(lineNumber++,"SUB",right);
                    insertSingleCommand(lineNumber++,"STORE",left);
                    insertSingleCommand(lineNumber++,"LOAD",regStore);
                    insertSingleCommand(lineNumber++,"SHL",-1); // !!!!
                    insertSingleCommand(lineNumber++,"INC",-1); // !!!!
                    insertSingleCommand(lineNumber++,"STORE",regStore);
                    
                    insertSingleCommand(lineNumber++,"LOAD",right);
                    insertSingleCommand(lineNumber++,"SHR",-1);
                    insertSingleCommand(lineNumber++,"STORE",right);
                    insertSingleCommand(lineNumber,"JUMP",lineNumber-21);
                    lineNumber++;

                    insertSingleCommand(lineNumber++,"LOAD",left);
                    $<retVar>$.varName="ACC";
                    int jzeroJumper=popJump();
                    getSingleCommandByIndex(jzeroJumper)->arg=lineNumber;
                    jzeroJumper=popJump();
                    getSingleCommandByIndex(jzeroJumper)->arg=lineNumber;
                }
                ;

condition       : value EQ value
                {
                    if(inWhileLoop==1)
                        pushJump(lineNumber);
                    if($<retVar>1.isDirect==1){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>1.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>1.memAddress);
                    }
                    if($<retVar>3.isDirect==1){
                        //co jesli to jest array!?
                        insertSingleCommand(lineNumber++,"SUB",$<retVar>3.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"SUBI",$<retVar>3.memAddress);
                    }
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+2);
                    lineNumber++;
                    insertSingleCommand(lineNumber,"JUMP",lineNumber+4);
                    lineNumber++;
                    if($<retVar>3.isDirect==1){
                        //co jesli to jest array!?
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>3.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>3.memAddress);
                    }
                    if($<retVar>1.isDirect==1){
                        insertSingleCommand(lineNumber++,"SUB",$<retVar>1.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"SUBI",$<retVar>1.memAddress);
                    }
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+3);
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"ZERO",-1);
                    insertSingleCommand(lineNumber,"JUMP",lineNumber+2);
                    lineNumber++;                
                    insertSingleCommand(lineNumber++,"INC",-1);
                }
                | value NEQ value
                {
                    if(inWhileLoop==1)
                        pushJump(lineNumber);
                    if($<retVar>1.isDirect==1){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>1.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>1.memAddress);
                    }
                    if($<retVar>3.isDirect==1){
                        //co jesli to jest array!?
                        insertSingleCommand(lineNumber++,"SUB",$<retVar>3.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"SUBI",$<retVar>3.memAddress);
                    }
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+2);
                    lineNumber++;
                    insertSingleCommand(lineNumber,"JUMP",lineNumber+4);
                    lineNumber++;
                    if($<retVar>3.isDirect==1){
                        //co jesli to jest array!?
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>3.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>3.memAddress);
                    }
                    if($<retVar>1.isDirect==1){
                        insertSingleCommand(lineNumber++,"SUB",$<retVar>1.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"SUBI",$<retVar>1.memAddress);
                    }
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+3);
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"ZERO",-1);
                    insertSingleCommand(lineNumber++,"INC",-1);
                }
                | value LE value
                {
                    if(inWhileLoop==1)
                        pushJump(lineNumber);
                    if($<retVar>3.isDirect==1){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>3.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>3.memAddress);
                    }
                    if($<retVar>1.isDirect==1){
                        //co jesli to jest array!?
                        insertSingleCommand(lineNumber++,"SUB",$<retVar>1.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"SUBI",$<retVar>1.memAddress);
                    }
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+3);
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"ZERO",-1);
                    insertSingleCommand(lineNumber++,"INC",-1);
                }
                | value GE value
                {
                    if(inWhileLoop==1)
                        pushJump(lineNumber);
                    if($<retVar>1.isDirect==1){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>1.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>1.memAddress);
                    }
                    if($<retVar>3.isDirect==1){
                        //co jesli to jest array!?
                        insertSingleCommand(lineNumber++,"SUB",$<retVar>3.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"SUBI",$<retVar>3.memAddress);
                    }
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+3);
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"ZERO",-1);
                    insertSingleCommand(lineNumber++,"INC",-1);
                }
                | value LEQ value
                {
                    if(inWhileLoop==1)
                        pushJump(lineNumber);
                    if($<retVar>1.isDirect==1){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>1.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>1.memAddress);
                    }
                    if($<retVar>3.isDirect==1){
                        //co jesli to jest array!?
                        insertSingleCommand(lineNumber++,"SUB",$<retVar>3.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"SUBI",$<retVar>3.memAddress);
                    }
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+3);
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"ZERO",-1);
                    insertSingleCommand(lineNumber,"JUMP",lineNumber+2);
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"INC",-1);
                }
                | value GEQ value
                {
                    if(inWhileLoop==1)
                        pushJump(lineNumber);
                    if($<retVar>3.isDirect==1){
                        insertSingleCommand(lineNumber++,"LOAD",$<retVar>3.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"LOADI",$<retVar>3.memAddress);
                    }
                    if($<retVar>1.isDirect==1){
                        //co jesli to jest array!?
                        insertSingleCommand(lineNumber++,"SUB",$<retVar>1.memAddress);
                    }else{
                        insertSingleCommand(lineNumber++,"SUBI",$<retVar>1.memAddress);
                    }
                    insertSingleCommand(lineNumber,"JZERO",lineNumber+3);
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"ZERO",-1);
                    insertSingleCommand(lineNumber,"JUMP",lineNumber+2);
                    lineNumber++;
                    insertSingleCommand(lineNumber++,"INC",-1);
                }
                ;

value           : NUMBER
                {   
                    insertNumberIntoAccumulator($<value>1);
                    if(inWhileLoop==1){
                        numberLoaded++;
                        insertLoopRange(loopCounter++);
                        $<retVar>$.varName=stack->varName;
                        $<retVar>$.isArray=0;
                        $<retVar>$.memAddress=stackPointer-1;
                        $<retVar>$.isDirect=1;
                        insertSingleCommand(lineNumber++,"STORE",stackPointer-1);
                        //TO-DO
                    }else{
                        insertSingleCommand(lineNumber++,"STORE",reg);
                        $<retVar>$.varName="REG";
                        $<retVar>$.isArray=0;
                        $<retVar>$.memAddress=reg;
                        $<retVar>$.isDirect=1;
                        reg=(reg+1)%regMax;
                    }
                }
                | identifier
                {
                    if(memoryArray[$<retVar>1.memAddress]==-1){
                        yyerror2(2,$<retVar>1.varName);
                    }
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
                    
                    insertSingleCommand(lineNumber++,"LOAD",var1->memStart-1);
                    insertSingleCommand(lineNumber++,"ADD",var3->memStart);
                    //printf("%s-%d-%d-%d\n",var3->varName,var3->isArray,var3->memStart,var3->varSize);
                    if(inWhileLoop==1){
                        numberLoaded++;
                        insertLoopRange(loopCounter++);
                        memoryArray[stackPointer-1]=0;
                        $<retVar>$.memAddress=stackPointer-1;
                    }else{
                        $<retVar>$.memAddress=reg;
                        reg=(reg+1)%regMax;
                    }
                        $<retVar>$.varName=var1->varName;
                        $<retVar>$.isArray=var1->isArray;
                        $<retVar>$.isDirect=0;
                        insertSingleCommand(lineNumber++,"STORE",$<retVar>$.memAddress);
                }
                | V LEFT NUMBER RIGHT
                {
                    VariableStack* var1=getVariableByName($<string>1);
                    if(var1==NULL){
                        yyerror2(1,$<string>1);
                    }else if (var1->isArray==0){
                        yyerror2(3,$<string>1);
                    }else if(var1->varSize <= $<value>3){
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
    insertNewVariable("R1",1,0,0);
    insertNewVariable("R2",1,0,0);
    insertNewVariable("R3",1,0,0);
    insertNewVariable("R4",1,0,0);
    insertNewVariable("R5",1,0,0);
    insertNewVariable("R6",1,0,0);
    insertNewVariable("R7",1,0,0);
    insertNewVariable("R8",1,0,0);
    insertNewVariable("R9",1,0,0);
    insertNewVariable("R10",1,0,0);
    memoryArray[0]=memoryArray[1]=memoryArray[2]=memoryArray[3]=0;
    memoryArray[4]=memoryArray[5]=memoryArray[6]=memoryArray[7]=memoryArray[8]=memoryArray[9]=0;
    construct(10000);
    yyparse();
    insertSingleCommand(lineNumber++,"HALT",-1);
    writeIntoFile("output");
    printf("STACK POINTER NA KONIEC: %d\n",stackPointer);
    freeStructures();
    free(memoryArray);
    return 0;
}

void freeStructures(){
    cleanJumpStack();
    clearStack();
    cleanUp();
}

