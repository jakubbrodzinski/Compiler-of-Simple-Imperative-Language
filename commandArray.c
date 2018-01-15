#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#ifndef COMMAND_ARR
#define COMMAND_ARR

struct SingleCommand{
    char * command;
    //if -1 then no label. (arg==-1) ZERO , (arg=15) STORE 15
    int arg;
};
int size=0;
struct SingleCommand* commandArray;

struct SingleCommand* getSingleCommandByIndex(int index){
    return commandArray+index;
}

struct SingleCommand* insertSingleCommand(int index,char* com,int a){
    if(index>=size){
        commandArray=(struct SingleCommand*) realloc(commandArray,(size+1000)*sizeof(struct SingleCommand));
        size+=1000;
    }
    commandArray[index].command=strdup(com);
    commandArray[index].arg=a;
    return commandArray+index;
}

void construct(int s){
    size=s;
    commandArray=(struct SingleCommand*) malloc(size*sizeof(struct SingleCommand));
}

void cleanUp(){
    int isLine=1;
    for(int i=0;i<size && isLine==1;i++){
        if(strcmp(commandArray[i].command,"HALT")==0){
            isLine=0;
        }
        free(commandArray[i].command);
    }
    free(commandArray);
}

void writeIntoFile(char* filename){
        FILE *fp;
        fp = fopen(filename, "w+");
        if(fp == NULL) {
            fprintf(stderr, "FILERR '%s'\n", filename);
        }
        for(int i=0;i<size;i++){
                if(commandArray[i].arg==-1){
                    fprintf(fp, "%s\n",commandArray[i].command);
                }else{
                    fprintf(fp, "%s %d \n",commandArray[i].command,commandArray[i].arg);
                }
                if(strcmp(commandArray[i].command,"HALT")==0){
                    break;
                }
        }
        fclose(fp);
        }
#endif
