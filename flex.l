%{
  #include "bison.h"
  #include <stdlib.h>
  #include <stdio.h>
  #include <string.h>
  unsigned int lineno=1;
  int yylex();
  int yyerror(char* err){
    printf("%s\nLine: %d\n",err,lineno);
    exit(1);
  }
%}

%x COMMENT
NUMBER  [0-9]+
WHITE   [ \t]+

%%

VAR         return VAR;
BEGIN       return BEGIN;
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
                yylval.string=strdup(yytext);
                return V;
            }

\(                   BEGIN(COMMENT);
<COMMENT><<EOF>>    yyerror("Nie zakonczony komentarz!");
<COMMENT>[^\)]*      ;
<COMMENT>\)          BEGIN(INITIAL);

.           { yyerror("Błedny znak"); }
\n          lineno++;
{WHITE}     ;

%%
