%{
#include <stdio.h>
#include "y.tab.h"
int yyerror(char *);
%}


DIGIT [0-9]
ID [a-z]
DOT [\.]

%%

"else"    return(ELSE);
"if" 	  return(IF);   
"print"   return(PRINT); 
"for"     return(FOR);
"while"   return(WHILE);



[-]?{DIGIT}+  {
            yylval.intval = atoi(yytext);
            return(NUMBER);
        }

[-]?{DIGIT}+{DOT}{DIGIT}+  {
            yylval.deci = atof(yytext);
            return(DECI);
        }


{ID}		{
				yylval.id = *yytext;
				return IDENTIFIER;
			}
[-+*/><=;()^{},]  {
              return *yytext;
        }
[ \t]  
  
.       {ECHO; yyerror (" unexpected character");}



 
%%

int yywrap (void) {return 1;}