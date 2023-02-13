%{
#include <stdio.h>
#include "y.tab.h"
int yyerror(char *);
typedef enum { typeCon, typeId, typeOpr } nodeEnum;

typedef struct {
 int value;
} conNodeType;

typedef struct {
 int i; 
} idNodeType;

typedef struct {
 int oper; 
 int nops; 
 struct nodeType **op; 
} oprNodeType;

typedef struct  {
 nodeEnum type; /* type of node */
 conNodeType con; /* constants */
 idNodeType id; /* identifiers */
 oprNodeType opr; /* operators */
} nodeType;


%}


DIGIT [0-9]
ID [a-z]

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