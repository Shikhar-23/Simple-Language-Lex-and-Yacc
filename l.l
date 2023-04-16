%{
#include <stdio.h>
#include "y.tab.h"
int yyerror(char *);
int lineno = 0;
%}


DIGIT [0-9]
ID [a-z_A-Z]
ID2[a-zA-Z0-9_]
DOT [\.]

%%

"else"    return(ELSE);
"if" 	  return(IF);   
"write"   return(WRITE); 
"read"    return(READ);
"while"   return(WHILE);
"function" return(FUNCTION);



[-]?{DIGIT}+  {
            yylval.intval = atoi(yytext);
            return(NUMBER);
        }

[-]?{DIGIT}+{DOT}{DIGIT}+  {
            yylval.deci = atof(yytext);
            return(DECI);
        }


{ID}{ID2}*		{
				yylval.id = yytext;
				return IDENTIFIER;
			}
[-+*/><=;()^{},]  {
              return *yytext;
        }
[ \t]  

[\n]	{lineno++;}
.      {ECHO; yyerror (" unexpected symbol");}



 
%%

int yywrap (void) {return 1;}