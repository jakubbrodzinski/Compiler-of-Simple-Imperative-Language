#include <stdlib.h>
#ifndef JUMP_STCK
#define JUMP_STCK

struct jumpStack{
    int lineNumber;
    struct jumpStack* nextVar;
};
typedef struct jumpStack JumpStack;
JumpStack* stackJump=NULL;

int popJump(){
    if(stackJump==NULL)
        return -1;
    int ret=stackJump->lineNumber;
    JumpStack* temp=stackJump->nextVar;
    stackJump->nextVar=NULL;
    free(stackJump);
    stackJump=temp;
    return ret;
}
void pushJump(int lineN){
    JumpStack* new=(JumpStack*) malloc(sizeof(JumpStack));
    new->lineNumber=lineN;
    new->nextVar=stackJump;
    stackJump=new;
}

void cleanJumpStack(){
    while(stackJump!=NULL)
        popJump();
}
#endif
