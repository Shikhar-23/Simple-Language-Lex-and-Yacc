%{
#include<stdio.h>
#include <math.h>
#include <stdlib.h>
int yyerror(char*);
int yylex();
extern FILE* yyin;
int symbols[26];
int getInd(char symbol);
int getVal(char symbol);
void assignVal(char symbol, int);
void assignValDouble(char symbol, double);
%}


%union{
  int intval;
  char id;
  double deci;
}

%start program
%token <intval> NUMBER /* Simple integer */
%token <id> IDENTIFIER /* Simple identifier */
%token <deci> DECIMAL /* Simple decimal */

%token SKIP THEN ELSE FI DO END IF
%token INTEGER READ WRITE LET IN PRINT
%token ASSGNOP
%type<intval> exp stmt;
%left '='
%left GE LE EQ NE '>' '<'
%left '+' '-'
%left '*' '/'
%right '^'
%nonassoc UMINUS

%%
program: function {
           exit(0); 
         }
        ;

function: function stmt 
          |
          ;
  
stmt: ';' 
       | PRINT exp ';' { printf("%d\n", $2); }
       | exp ';' { $$ = $1; }
       | IDENTIFIER '=' NUMBER ';' {assignVal($1, $3);}
       | IDENTIFIER '=' DECIMAL ';' {assignValDouble($1, $3);}
       | IDENTIFIER '=' exp ';' {assignVal($1, $3); }
;

      


exp : NUMBER { $$ = $1; }
    | IDENTIFIER {$$ = getVal($1); }
    | exp '<' exp { $$ = $1 < $3; }
    | exp '=' exp { $$ = $1 = $3 ;}
    | exp '>' exp { $$ = $1 > $3 ;}
    | exp '+' exp { $$ = $1 + $3 ;}
    | exp '-' exp { $$ = $1 - $3 ;}
    | exp '*' exp { $$ = $1*$3;}
    | exp '/' exp { $$ = $1/$3;}
    | exp '^' exp { $$ = pow($1, $3); }
    | '(' exp ')' { $$ = $2; }
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
      printf("Pass Filename as parameter: Ex -> ./a demo.txt");
      exit(1);
  }
  if(!(yyin = fopen(argv[1],"r"))){ 
       printf("cannot open file\n");exit(1);
 }
  yyparse();

  return 0;
}

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