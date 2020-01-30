#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#ifndef VAR_LIST
#define VAR_LIST
struct variableStack{
    char* varName;
    long varSize;
    int isArray;
    int startIndex;
    long memStart;
    int varType;
    int isUsed;

    struct variableStack* nextVar;
};
typedef struct variableStack VariableStack;

long stackPointer=0;
VariableStack* stack=NULL;

int isAlreadyDeclared(char * name){
    VariableStack* top=stack;
    while(top!=NULL){
        if(strcmp(name,top->varName)==0){
            return 1;
        }
        top=top->nextVar;
    }
    return 0;
}
/*
 * -1 - already declared
 *  1 - OK
 */
int insertNewVariable(char * name,long size,int isArr,int isIterator){
    return insertNewVariableWithStartIndex(name,size,isArr,0,isIterator);
}

int insertNewVariableWithStartIndex(char * name,long size,int isArr,int startIndex,int isIterator){
    if(isAlreadyDeclared(name)){
        return -1;
    }
    VariableStack* var=(VariableStack*) malloc(sizeof(VariableStack));
    var->varName=(char*) malloc((strlen(name)+1)*sizeof(char));
    strcpy(var->varName,name);
    if(isArr){
        var->varSize=size;
        var->memStart=stackPointer+1;
        stackPointer+=(size+1);    
    }else{
        var->varSize=1;
        var->memStart=stackPointer;
        stackPointer+=1;            
    }
    var->isArray=isArr;
    var->startIndex=startIndex;
    var->varType=isIterator;
    var->isUsed=-1;

    var->nextVar=stack;
    stack=var;
    return 1;
}

int insertLoopRange(int loopC){
    VariableStack* var=(VariableStack*) malloc(sizeof(VariableStack));
    var->varName=(char*) malloc(4*sizeof(char));
    var->varName[0]='I';
    var->varName[1]='T';
    var->varName[2]=loopC+48;
    var->varName[3]='\0';
    var->varSize=1;
    var->memStart=stackPointer;
    var->isUsed=-1;
    stackPointer+=1;
    var->isArray=0;
    var->varType=1;

    var->nextVar=stack;
    stack=var;
    return 1;
}

void clearStack(){
    VariableStack* temp;
    while(stack!=NULL){
        temp=stack;
        stack=stack->nextVar;
        temp->nextVar=NULL;
        free(temp->varName);
        free(temp);
    }
    stackPointer=0;
}

/*
 * -1 usuwasz nieiterator
 *  1 OK
 */
int removeFromTop(){
    if(stack->varType!=1)
        return -1;
    VariableStack* top=stack;
    if(top->isArray==1){
            stackPointer=stackPointer-1;
    }
    stackPointer=stackPointer-(top->varSize);
    stack=stack->nextVar;
    free(top->varName);
    free(top);
    return 1;
}

VariableStack* getFromTop(){
    return stack;
}
VariableStack* getVariableFromMemory(long memoryCell){
    VariableStack* temp=stack;
    if(temp->memStart+temp->varSize-1<memoryCell)
        return NULL;
    while((temp->isArray==1 && temp->memStart-1>memoryCell) || (temp->isArray==0 && temp->memStart>memoryCell))
        temp=temp->nextVar;
    return temp;
}
VariableStack* getVariableByName(char * name){
    VariableStack* top=stack;
    while(top!=NULL){
        if(strcmp(name,top->varName)==0){
            return top;
        }
        top=top->nextVar;
    }
    return NULL;
}
#endif
