%{
#include<stdio.h>
#include <math.h>
#include <stdlib.h>
#include <stdarg.h>
#include "util.h"
int yyerror(char*);
int yylex();
extern FILE* yyin;
double symbols[26];
int getInd(char symbol);
int getVal(char symbol);
void assignVal(char symbol, int);
void assignValDouble(char symbol, double);

NodeType *opr(int oper, int nops, ...);
NodeType *id(int i);
NodeType *con(int value);
NodeType *flo(float);

float process(NodeType *p);

%}

%union {
  int intval;
  char id;
  float deci;
  struct NodeType *nPtr;
};

%start program
%token <intval> NUMBER /* Simple integer */
%token <id> IDENTIFIER /* Simple identifier */
%token <deci> DECIMAL /* Simple decimal */
%token ELSE IF
%token PRINT
%token ASSGNOP
%token WHILE FOR

%type <nPtr> stmt exp stmt_list

%nonassoc IFX
%nonassoc ELSE
%left '='
%left GE LE EQ NE '>' '<'
%left '+' '-'
%left '*' '/'
%right '^'
%nonassoc UMINUS
%%
program: function {  exit(0);  }
        ;

function: function stmt { process($2); }
          | 
          ;
  
stmt:  ';' { $$ = opr(';', 2, NULL, NULL); }
       | exp ';' { $$ = $1; }
       | PRINT exp ';' { $$ = opr(PRINT, 1, $2); }
       | IDENTIFIER '=' exp ';' { $$ = opr('=', 2, id($1), $3); }
       | WHILE '(' exp ')' stmt { $$ = opr(WHILE, 2, $3, $5); }
       | IF '(' exp ')' stmt %prec IFX { $$ = opr(IF, 2, $3, $5); }
       | IF '(' exp ')' stmt ELSE stmt { $$ = opr(IF, 3, $3, $5, $7); }
       | '{' stmt_list '}' { $$ = $2; }
       ;

stmt_list:
 stmt { $$ = $1; }
 | stmt_list stmt { $$ = opr(';', 2, $1, $2); }
 ; 
      


exp : NUMBER { $$ = con($1); }
     | IDENTIFIER {$$ = id($1); }
     | DECIMAL {$$ = flo($1); }
     | exp '+' exp { $$ = opr('+', 2, $1, $3); }
     | exp '-' exp { $$ = opr('-', 2, $1, $3); }
     | exp '*' exp { $$ = opr('*', 2, $1, $3); }
     | exp '/' exp { $$ = opr('/', 2, $1, $3); }
     | exp '<' exp { $$ = opr('<', 2, $1, $3); }
     | exp '>' exp { $$ = opr('>', 2, $1, $3); } 
     | exp '=' exp { $$ = opr('=', 2, $1, $3); }
     | exp '^' exp { $$ = opr('^', 2, $1, $3); }
     | '(' exp ')' { $$ = $2; }
     | '-' exp %prec UMINUS { $$ = opr(UMINUS, 1, $2); } 

;

%%

int yyerror(char *s){
  fprintf(stderr, "%s\n", s); 
  return 0;
}

int main(int argc, char **argv){
  for(int i=0; i<26; i++) {
    symbols[i] = 0;
  }
   FILE *f;
  if(argc != 2){
      printf("Pass Filename as parameter: Ex -> a.exe demo.txt");
      exit(1);
  }
  if(!(yyin = fopen(argv[1],"r"))){ 
       printf("cannot open file\n");exit(1);
 }
  yyparse();

  return 0;
}

/*
int getInd(char symbol){
  if(symbol >= 'a' && symbol <= 'z') return (int)(symbol - 'a');
  else yyerror("Not Valid variable Symbol");
}

void assignVal(char symbol, int val){
  symbols[getInd(symbol)] = val;
}

void assignValDouble(char symbol, double val){
  symbols[getInd(symbol)] = val;
}

int getVal(char symbol){
  return symbols[getInd(symbol)];
}
*/

NodeType *opr(int oper, int nops, ...) {
 va_list ap;
 NodeType *p;
 int i;
 if ((p = malloc(sizeof(NodeType))) == NULL)
 yyerror("out of memory");
 if ((p->opr.op = malloc(nops * sizeof(NodeType))) == NULL)
 yyerror("out of memory");
 p->type = typeOpr;
 p->opr.oper = oper;
 p->opr.nops = nops;
 va_start(ap, nops);
 for (i = 0; i < nops; i++)
 p->opr.op[i] = va_arg(ap, NodeType*);
 va_end(ap);
 return p;
} 

NodeType *con(int value) {
 NodeType *p;
 if ((p = malloc(sizeof(NodeType))) == NULL)
 yyerror("out of memory");
 p->type = typeCon;
 p->con.value = value;
 return p;
}

NodeType *flo(float value) {
 printf("%f\n", value);
 NodeType *p;
 if ((p = malloc(sizeof(NodeType))) == NULL)
 yyerror("out of memory");
 p->type = typeFlo;
 p->flo.value = value;
 return p;
}

NodeType *id(int i) {
 NodeType *p;
 if ((p = malloc(sizeof(NodeType))) == NULL)
 yyerror("out of memory");
 p->type = typeId;
 p->id.i = i;
 return p;
} 

float process(NodeType *p) {
 if (!p) return 0;
 switch(p->type) {
   case typeCon: return p->con.value;
   case typeFlo: return p->flo.value;
   case typeId: {
                 return symbols[p->id.i];
                }
   case typeOpr:
   switch(p->opr.oper) {
   case WHILE: while(process(p->opr.op[0]))  
               process(p->opr.op[1]);
              return 0;
   case IF: if (process(p->opr.op[0])) process(p->opr.op[1]);
            else if (p->opr.nops > 2) process(p->opr.op[2]); return 0;
   case PRINT:  {
                  if(p -> opr.op[0] -> type == typeFlo){
                    printf("here\n");
                    printf("%f\n", process(p->opr.op[0])); return 0;
                  }
                  else {
                    printf("%d\n", process(p->opr.op[0])); return 0;
                  }
                }
   case ';': process(p->opr.op[0]); return process(p->opr.op[1]);
   case '=': return symbols[p->opr.op[0]->id.i] = process(p->opr.op[1]);
   case UMINUS: return -process(p->opr.op[0]);
   case '+': return process(p->opr.op[0]) + process(p->opr.op[1]);
   case '-': return process(p->opr.op[0]) - process(p->opr.op[1]);
   case '*': return process(p->opr.op[0]) * process(p->opr.op[1]);
   case '/': return 1.0 * process(p->opr.op[0]) / process(p->opr.op[1]);
   case '<': return process(p->opr.op[0]) < process(p->opr.op[1]);
   case '>': return process(p->opr.op[0]) > process(p->opr.op[1]);
   case '^': return pow(process(p->opr.op[0]), process(p->opr.op[1]));
   default : yyerror("Operator not found");

   }
 }
 return 0;
} 

