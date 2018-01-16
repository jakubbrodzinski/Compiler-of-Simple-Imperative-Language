%{
  #include "bison.h"
  #include <stdlib.h>
  #include <stdio.h>
  #include <string.h>
  unsigned int lineno=1;
  int yylex();
  int yyerror(char* err){
    printf("%s\nLine: %d\n",err,lineno);
  }
  int yyerror2(int errNumber,char* varName){
    switch(errNumber){
        case 1:
            printf("Zmienna '%s' nie została zadeklarowana.\n",varName);
            break;
        case 2:
            printf("Zmienna '%s' nie została zainicjowana.\n",varName);
            break;
        case 3:
            printf("Zmienna '%s' nie jest tablicą.\n",varName);
            break;
        case 4:
            printf("Zmienna '%s' jest tablicą.\n",varName);
            break;
        case 5:
            printf("'%s'- IndexOfOutBoundsEx\n",varName);
            break;
        case 6:
            printf("Powtarzająca się deklaracja zmiennej '%s'.\n",varName);
            break;
        case 7:
            printf("Błędne znaki.\n");
            break;
        case 8:
            printf("Niezamknięty komentarz.\n");
            break;
        case 9:
            printf("Modyfikowany iterator pętli '%s'\n",varName);
            break;
    }    
    printf("Line: %d\n",lineno);
    exit(1);
  }
%}

%x COMMENT
NUMBER  [0-9]+
WHITE   [ \t]+

%%

VAR         return VAR;
BEGIN       return BEG;
END         return END;

FOR         return FOR;
FROM        return FROM;
TO          return TO;
DOWNTO      return DOWNTO;
DO          return DO;
ENDFOR      return ENDFOR;

WHILE       return WHILE;
ENDWHILE    return ENDWHILE;

IF          return IF;
THEN        return THEN;
ELSE        return ELSE;
ENDIF       return ENDIF;

READ        return READ;
WRITE       return WRITE;

"+"         return ADD;
"-"         return SUB;
"*"         return MUL;
"/"         return DIV;
"%"         return MOD;

"="         return EQ;
"<>"        return NEQ;
"<"         return LE;
">"         return GE;
"<="        return LEQ;
">="        return GEQ;
":="        return AS;
"["         return LEFT;
"]"         return RIGHT;
";"         return ENDL;

{NUMBER}    {
                yylval.value=strtoull(yytext,NULL,10);
                return NUMBER;
            }
[_a-z]+     {
                yylval.string=(char*) malloc((strlen(yytext)+1)*sizeof(char));
                strcpy(yylval.string,yytext);
                return V;
            }

\(                   BEGIN(COMMENT);
<COMMENT><<EOF>>    yyerror2(8,NULL);
<COMMENT>[^\)]*      ;
<COMMENT>\)          BEGIN(INITIAL);

{WHITE}     ;
\n          lineno++;
.           { yyerror2(7,NULL); }

%%
