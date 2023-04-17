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
"write"   { 
            // printf("write "); 
            return(WRITE); 
          }
"read"    return(READ);
"while"   return(WHILE);
"function" {
            // printf("function ");
            return(FUNCTION);
            }


[-]?{DIGIT}+  {
            yylval.intval = atoi(yytext);
            // printf("Number ");
            return(NUMBER);
        }

[-]?{DIGIT}+{DOT}{DIGIT}+  {
            yylval.deci = atof(yytext);
            // printf("Decimal ");

            return(DECI);
        }


{ID}{ID2}*		{
				yylval.id = yytext;
                // printf(yytext);
                // printf(" ");

				return IDENTIFIER;
			}
[-+*/><=()^{},;]  {
            //   printf(yytext);
            //   printf(" ");
              return *yytext;
        }
[ \t\n]  

.      {ECHO; yyerror (" unexpected symbol");}



 
%%

int yywrap (void) {return 1;}