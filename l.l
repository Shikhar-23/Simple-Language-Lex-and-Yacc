%{
#include <stdio.h>
#include "y.tab.h"
int yyerror(char *);
%}


DIGIT [0-9]
ID [a-z]

%%

"do" 		return(DO); 
"else"    return(ELSE);
"end"     return(END);
"if" 		return(IF); 
"in"		return(IN); 
"number" return(NUMBER); 
"let"     return(LET); 
"read" 	return(READ); 
"skip" 	return(SKIP); 
"then" 	return(THEN); 
"print"   return(PRINT); 


{DIGIT}+  {
            yylval.intval = atoi(yytext);
            return(NUMBER);
        }

{ID}		{
				yylval.id = *yytext;
				return IDENTIFIER;
			}
[-+*/><=;()^]  {
              return *yytext;
        }
[ \t]  
  
.       {ECHO; yyerror (" unexpected character");}



 
%%

int yywrap (void) {return 1;}