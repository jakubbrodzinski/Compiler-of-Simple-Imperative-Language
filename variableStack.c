#include <stdio.h>
#include <string.h>
#include <stdlib.h>
extern int* memoryArray;

struct variableStack{
    char* varName;
    int varSize;
    int isArray;
    int memStart;
    int varType;

    struct variableStack* nextVar;
};
typedef struct variableStack VariableStack;

int stackPointer=0;
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
 */
int insertNewVariable(char * name,int size,int isArr,int isIterator){
    if(isAlreadyDeclared(name)){
        return -1;
    }
    VariableStack* var=(VariableStack*) malloc(sizeof(VariableStack));
    var->varName=(char*) malloc((strlen(name)+1)*sizeof(char));
    strcpy(var->varName,name);
    if(isArr)
        var->varSize=size;
    else
        var->varSize=1;
    var->isArray=isArr;
    var->varType=isIterator;

    var->memStart=stackPointer;
    memoryArray=(int*) realloc(memoryArray,(stackPointer+size)*sizeof(int));
    for(int i=stackPointer;i<stackPointer+size;i++)
        memoryArray[i]=-1;
    if(isArr)
        stackPointer+=size;
    else
        stackPointer+=1;

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
    stackPointer=stackPointer-(top->varSize);
    memoryArray=(int*) realloc(memoryArray,stackPointer*sizeof(int));
    stack=stack->nextVar;
    free(top->varName);
    free(top);
    return 1;
}

VariableStack* getFromTop(){
    return stack;
}

VariableStack* getVariableFromMemory(int memoryCell){
    VariableStack* temp=stack;
    if(temp->memStart+temp->varSize-1<memoryCell)
        return NULL;
    while(temp->memStart>memoryCell)
        temp=temp->nextVar;
    return temp;
}
