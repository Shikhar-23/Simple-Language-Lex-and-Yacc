%{
#include<stdio.h>
#include <math.h>
#include <stdlib.h>
#include <stdarg.h>
#include "util.h"
int yyerror(char*);
int yylex();
extern FILE* yyin;
double symbols[256];
dataType sym[256];
NodeType *opr(int oper, int nops, ...);
NodeType *id(int i);
NodeType *num(int value);
NodeType *flo(float);

val *process(struct nodeType *p);
extern int lineno;
%}

%union {
  int intval;
  char id;
  float deci;
  struct nodeType *nPtr;
};

%start program
%token <intval> NUMBER /* Simple integer */
%token <id> IDENTIFIER /* Simple identifier */
%token <deci> DECI /* Simple decimal */
%token ELSE IF
%token WRITE READ
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
       | WRITE exp ';' { $$ = opr(WRITE, 1, $2); }
       | READ IDENTIFIER ';' { $$ = opr(READ, 1, id($2)); }
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
      


exp : NUMBER { $$ = num($1); }
     | IDENTIFIER {$$ = id($1); }
     | DECI {$$ = flo($1); }
     | exp '+' exp { $$ = opr('+', 2, $1, $3); }
     | exp '-' exp { $$ = opr('-', 2, $1, $3); }
     | exp '*' exp { $$ = opr('*', 2, $1, $3); }
     | exp '/' exp { $$ = opr('/', 2, $1, $3); }
     | exp '<' exp { $$ = opr('<', 2, $1, $3); }
     | exp '>' exp { $$ = opr('>', 2, $1, $3); } 
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
  for(int i=0; i<256; i++) {
    symbols[i] = 0;
    sym[i] = INTEGER;
  }
   FILE *f;
  if(argc != 2){
      printf("Pass Filename as parameter: Ex -> a.exe demo.txt");
      exit(1);
  }
  if(!(yyin = fopen(argv[1],"r"))){ 
       printf("cannot open file\n"); exit(1);
 }
  yyparse();

  return 0;
}

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

NodeType *num(int value) {
 NodeType *p;
 if ((p = malloc(sizeof(NodeType))) == NULL)
 yyerror("out of memory");
 p->type = typeCon;
 p->num.value = value;
 p->dType = INTEGER;
 return p;
}

NodeType *flo(float value) {
 NodeType *p;
 if ((p = malloc(sizeof(NodeType))) == NULL)
 yyerror("out of memory");
 p->type = typeFlo;
 p->flo.value = value;
 p->dType = DECIMAL;
 return p;
}

NodeType *id(int i) {
 NodeType *p;
 if ((p = malloc(sizeof(NodeType))) == NULL)
    yyerror("out of memory");
 p->type = typeId;
 p->id.i = i;
 p -> dType = sym[i];
 return p;
} 

val *process(NodeType *p) {
 if (!p) return 0;
 val *ret;
 ret = malloc(sizeof(val));
 ret -> dType = INTEGER;
 ret -> num = 0;
 ret -> flo = 0;
 switch(p->type) {
   case typeCon: {
                    ret->dType = INTEGER;
                    ret->num = p -> num.value; 
                    return ret;
                 }
   case typeFlo: {
                    ret->dType = DECIMAL;
                    ret->flo = p -> flo.value; 
                    return ret;
                 }
   case typeId:  {
                  ret -> dType = p -> dType;
                  if(p -> dType == INTEGER){
                    ret -> num = (int) symbols[p -> id.i]; 
                  }
                  else if(p -> dType == DECIMAL){
                    ret -> flo = symbols[p -> id.i];
                  }
                  return ret;
                 }
    case typeOpr:
       switch(p->opr.oper) {
       case WHILE: {
                      while(1){
                        val *x = process(p -> opr.op[0]);
                        if(x -> dType == INTEGER && x -> num == 0) break;
                        if(x -> dType == DECIMAL && x -> flo == 0) break;
                        process(p->opr.op[1]);
                    }  
                    return NULL;
                  }
       case IF: {
                  val *x = process(p -> opr.op[0]);
                  if (!((x -> dType == INTEGER && x -> num == 0) || (x -> dType == DECIMAL && x -> flo == 0))){
                      process(p->opr.op[1]);
                      return NULL;
                  }  
                  else if (p->opr.nops > 2) {
                    process(p->opr.op[2]); return NULL;
                  }
              }
       case READ: {
                    printf("Enter Value of Variable: ");
                    float value;
                    scanf("%f", &value);
                    if (value != (int)value){
                      sym[p->opr.op[0]->id.i] = DECIMAL;
                      symbols[p->opr.op[0]->id.i] = value;
                    }
                    else{
                      sym[p->opr.op[0]->id.i] = INTEGER;
                      symbols[p->opr.op[0]->id.i] = (int)value;
                    }
                    return NULL;
                  }
       case WRITE:  {
                      val *x = process(p -> opr.op[0]);
                      if(x -> dType == DECIMAL){
                        printf("%f\n", x -> flo); return NULL;
                      }
                      else if(x -> dType == INTEGER) {
                        printf("%d\n", x -> num); return NULL;
                      }
                    }
       case ';': {
                    process(p->opr.op[0]);  
                    process(p->opr.op[1]);
                    return NULL;
                 }
       case '=': {
                    val *x = process(p->opr.op[1]);
                    sym[p->opr.op[0]->id.i] = x -> dType;
                    if(x -> dType == DECIMAL) {
                        symbols[p->opr.op[0]->id.i] = x -> flo;
                    }
                    else if(x -> dType == INTEGER) {
                      symbols[p->opr.op[0]->id.i] = x -> num;
                    }
                    return NULL;
                 }
       case UMINUS: {
                      val *x = process(p->opr.op[0]);
                      x -> flo = - x -> flo;
                      x -> num = - x -> num;
                      return x;
                    }
       case '+': {
                    val *l = process(p->opr.op[0]);
                    val *r = process(p->opr.op[1]);
                    if(l -> dType != r -> dType){
                      printf("Warning: Datatypes of expressions are different\n");
                      ret -> dType = DECIMAL;
                      if(l -> dType == INTEGER){
                        ret -> flo = l -> num;
                        ret -> flo += r -> flo;
                      }
                      else{
                        ret -> flo = l -> flo;
                        ret -> flo += r -> num;
                      }
                    }
                    else {
                      ret -> dType = INTEGER;
                      if(l -> dType == INTEGER){
                        ret -> num = l -> num;
                        ret -> num += r -> num;
                      }
                      else{
                        ret -> flo = l -> flo;
                        ret -> flo += r -> flo;
                      }
                    }

                    return ret;
                 }
       case '-': {
                    val *l = process(p->opr.op[0]);
                    val *r = process(p->opr.op[1]);
                    if(l -> dType != r -> dType){
                      printf("Warning: Datatypes of expressions are different\n");
                      ret -> dType = DECIMAL;
                      if(l -> dType == INTEGER){
                        ret -> flo = l -> num;
                        ret -> flo -= r -> flo;
                      }
                      else{
                        ret -> flo = l -> flo;
                        ret -> flo -= r -> num;
                      }
                    }
                    else {
                        ret -> dType = INTEGER;
                      if(l -> dType == INTEGER){
                        ret -> num = l -> num;
                        ret -> num -= r -> num;
                      }
                      else{
                        ret -> flo = l -> flo;                      
                        ret -> flo -= r -> flo;
                      }
                    }

                    return ret;
                 }
       case '*': {
                    val *l = process(p->opr.op[0]);
                    val *r = process(p->opr.op[1]);
                    if(l -> dType != r -> dType){
                      printf("Warning: Datatypes of expressions are different\n");
                      ret -> dType = DECIMAL;
                      if(l -> dType == INTEGER){
                        ret -> flo = l -> num;
                        ret -> flo *= r -> flo;
                      }
                      else{
                        ret -> flo = l -> flo;
                        ret -> flo *= r -> num;
                      }
                    }
                    else {
                        ret -> dType = INTEGER;
                      if(l -> dType == INTEGER){
                        ret -> num = l -> num;
                        ret -> num *= r -> num;
                      }
                      else{
                        ret -> flo = l -> flo;
                        ret -> flo *= r -> flo;
                      }
                    }

                    return ret;
                 }
       case '/': {
                    val *l = process(p->opr.op[0]);
                    val *r = process(p->opr.op[1]);
                    if(l -> dType != r -> dType){
                      printf("Warning: Datatypes of expressions are different\n");
                    }
                    if((r -> num == 0 && r -> dType == INTEGER) || (r -> flo == 0 && r -> dType == DECIMAL)){
                      yyerror("Division by zero is not defined");
                      exit(0);
                    }
                    ret -> dType = DECIMAL;
                    if(l -> dType == INTEGER ){
                      ret -> flo = 1.0 * l -> num;
                      if(r -> dType == INTEGER) ret -> flo /= r -> num;
                      else ret -> flo /= r -> flo;
                    }
                    else{
                      ret -> flo = 1.0 * l -> flo;
                      if(r -> dType == INTEGER) ret -> flo /= r -> num;
                      else ret -> flo /= r -> flo;
                    }                   

                    return ret;
                 }
       case '<': {
                    val *l = process(p->opr.op[0]);
                    val *r = process(p->opr.op[1]);
                    if(l -> dType != r -> dType){
                      printf("Warning: Datatypes of expressions are different\n");
                    }
                    ret -> dType = INTEGER;
                    if(l -> dType == INTEGER){
                      if(r -> dType == INTEGER){
                          ret -> num = (l -> num < r -> num);
                      }
                      else ret -> num = (l -> num < r -> flo);
                    }
                    else{
                      if(r -> dType == INTEGER){
                          ret -> num = (l -> flo < r -> num);
                      }
                      else ret -> num = (l -> flo < r -> flo);
                    }
                    return ret;
                 }
       case '>': {
                    val *l = process(p->opr.op[0]);
                    val *r = process(p->opr.op[1]);
                    if(l -> dType != r -> dType){
                      printf("Warning: Datatypes of expressions are different\n");
                    }
                    ret -> dType = INTEGER;
                    if(l -> dType == INTEGER){
                      if(r -> dType == INTEGER){
                          ret -> num = (l -> num > r -> num);
                      }
                      else ret -> num = (l -> num > r -> flo);
                    }
                    else{
                      if(r -> dType == INTEGER){
                          ret -> num = (l -> flo > r -> num);
                      }
                      else ret -> num = (l -> flo > r -> flo);
                    }
                    return ret;
                 }
       case '^': {
                    val *l = process(p->opr.op[0]);
                    val *r = process(p->opr.op[1]);
                    if(l -> dType != r -> dType){
                      printf("Warning: Datatypes of expressions are different\n");
                    }

                    ret -> dType = DECIMAL;
                    if(l -> dType == INTEGER ){
                      ret -> flo = 1.0 * l -> num;
                      if(r -> dType == INTEGER) ret -> flo = pow(ret -> flo, r -> num);
                      else ret -> flo = pow(ret -> flo, r -> flo);
                    }
                    else{
                      ret -> flo = 1.0 * l -> flo;
                      if(r -> dType == INTEGER) ret -> flo = pow(ret -> flo, r -> num);
                      else ret -> flo = pow(ret -> flo, r -> flo);
                    }                 

                    return ret;
                 }
       default : {
                  yyerror("Operator not found");
                  exit(0);
                  }

   }
  }
  return 0;
} 

