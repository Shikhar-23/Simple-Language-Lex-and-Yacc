%{
#include<stdio.h>
#include <math.h>
#include <stdlib.h>
#include <stdarg.h>
#include "util.h"
int yyerror(char*);
int yylex();
extern FILE* yyin;
#define MAX 10009
double symbols[MAX];
dataType sym[MAX];
st_info* address[MAX];

st_info *st_add(int oper, int nops, ...);
st_info *id(char * c);
st_info *func(char * c);

st_info *num(int value);
st_info *flo(float);
void add_func(struct st_info*, struct st_info*);
void add_class(st_info *cls_id, class_vars *stmt);
class_vars* add_var(class_vars *stmt, st_info *var);
class_vars* create_var(st_info *var);
st_info *cls(char *c);
st_info* get_val(st_info *cls_id, st_info *id);
void update_add(st_info *cls_id, st_info*id);
int hash(char *);
val *process(struct st_info *p);
%}

%union {
  int intval;
  char* id;
  float deci;
  struct st_info *nPtr;
  struct class_vars *clsvr;
};

%start program
%token <intval> NUMBER /* Simple integer */
%token <id> IDENTIFIER /* Simple identifier */
%token <deci> DECI /* Simple decimal */
%token ELSE IF
%token WRITE READ
%token ASSGNOP
%token WHILE FOR
%token FUNCTION
%token FUNC CLASS
%token GET_VAL
%type <nPtr> stmt exp stmt_list;
%type <clsvr> ClassVars;
%nonassoc IFX
%nonassoc ELSE
%left '='
%left '>' '<'
%left '+' '-'
%left '*' '/'
%right '^'
%nonassoc UMINUS
%%
program: Definitions { exit(0);  }
        ;
Definitions : functionDef Definitions 
          | classDef Definitions
          |
          ;
functionDef: FUNCTION IDENTIFIER '(' ')' stmt { add_func(func($2), $5); }
          ;
classDef: CLASS IDENTIFIER '{' ClassVars ';' '}'{ add_class(cls($2), $4);  } 
          ;
ClassVars: ClassVars ',' IDENTIFIER { $$ = add_var($1, id($3));}
           | IDENTIFIER {$$ = create_var(id($1)); }
          ; 
stmt:  ';' { $$ = st_add(';', 2, NULL, NULL); }
       | exp ';' { $$ = $1; }
       | WRITE exp ';' { $$ = st_add(WRITE, 1, $2); }
       | READ IDENTIFIER ';' { $$ = st_add(READ, 1, id($2)); }
       |IDENTIFIER '.' IDENTIFIER  '=' exp ';' {$$ = st_add('=', 3, cls($1), id($3), $5); }
       | IDENTIFIER '=' exp ';' { $$ = st_add('=', 2, id($1), $3); }
       | WHILE '(' exp ')' stmt { $$ = st_add(WHILE, 2, $3, $5); }
       | IF '(' exp ')' stmt %prec IFX { $$ = st_add(IF, 2, $3, $5); }
       | IF '(' exp ')' stmt ELSE stmt { $$ = st_add(IF, 3, $3, $5, $7); }
       | '{' stmt_list '}' { $$ = $2;}
       | IDENTIFIER '(' ')' ';' {$$ = st_add(FUNC, 1, func($1)); }
       | IDENTIFIER IDENTIFIER '(' ')' ';'{update_add(cls($1), id($2)); }
       ;

stmt_list:
 stmt { $$ = $1; }
 | stmt_list stmt { $$ = st_add(';', 2, $1, $2); }
 ; 
      


exp : NUMBER { $$ = num($1); }
     | IDENTIFIER {$$ = id($1); }
     | DECI {$$ = flo($1); }
     | exp '+' exp { $$ = st_add('+', 2, $1, $3); }
     | exp '-' exp { $$ = st_add('-', 2, $1, $3); }
     | exp '*' exp { $$ = st_add('*', 2, $1, $3); }
     | exp '/' exp { $$ = st_add('/', 2, $1, $3); }
     | exp '<' exp { $$ = st_add('<', 2, $1, $3); }
     | exp '>' exp { $$ = st_add('>', 2, $1, $3); } 
     | exp '^' exp { $$ = st_add('^', 2, $1, $3); }
     | '(' exp ')' { $$ = $2; }
     | '-' exp %prec UMINUS { $$ = st_add(UMINUS, 1, $2); } 
     | IDENTIFIER '.' IDENTIFIER {$$ = st_add(GET_VAL, 2, cls($1), id($3)) ; }


;

%%

int yyerror(char *s){
  fprintf(stderr, "%s\n", s); 
  return 0;
}

int main(int argc, char **argv){
  for(int i=0; i<MAX; i++) {
    symbols[i] = 0;
    sym[i] = INTEGER;
    address[i] = malloc(sizeof(address[i]));
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
void update_add(st_info *cls_id, st_info*id){
    address[id -> id.i] = address[cls_id-> id.i];
}
void add_class(st_info *cls_id, class_vars *stmt){
   class_vars* nw_cls = malloc(sizeof(class_vars));
   nw_cls->cls_vr = malloc(sizeof(class_vars)); 
   nw_cls->cls_vr = stmt;
   nw_cls->var = cls_id; 
  //  printf("Class added");
  //  printf(" %d ", cls_id->id.i);
   address[cls_id->id.i]->cls_vr = malloc(sizeof(class_vars));
   address[cls_id->id.i]->cls_vr = stmt;
  // printf("%d ", cls_id->id.i);
  //  printf("Class added");
}
class_vars* add_var(class_vars *stmt, st_info *var){
  stmt -> cls_vr = malloc(sizeof(class_vars));
  stmt -> cls_vr -> var = var;
  // printf("%d ", var->id.i);
  return stmt;
}
class_vars* create_var(st_info *var){
  class_vars *cls = malloc(sizeof(class_vars));
  cls->var = var;
  // printf("%d ", var->id.i);
  return cls;
}
void add_func(st_info *func_id, st_info *stmt_list){
  address[func_id->id.i] = stmt_list;
  char *M = "main";
  if(func_id->id.i == hash(M)){
    // printf("Main Function");
    process(stmt_list);
  }
  else{
  // printf("%d ", func_id->id.i);
    // printf("Function not Main");
  }
  return;
}
int hash(char *c){
  int ans = 0;
  while(*c == '_' || (*c >= 'a' && *c <= 'z') || (*c >= 'A' && *c <= 'Z') || (*c >= '0' && *c <= '9')){
    ans = ans * 31 + *c - 'a' + 1;
    ans %= MAX;
    c++;
  }
  // printf(c);
  return abs(ans);
}
st_info *st_add(int oper, int nops, ...) {
 va_list ap;
 st_info *p;
 int i;
 if ((p = malloc(sizeof(st_info))) == NULL)
    yyerror("out of memory");
 if ((p->st_add.op = malloc(nops * sizeof(st_info))) == NULL)
    yyerror("out of memory");
 p->type = typeStm;
 p->st_add.oper = oper;
 p->st_add.nops = nops;
 va_start(ap, nops);
 for (i = 0; i < nops; i++)
 p->st_add.op[i] = va_arg(ap, st_info*);
 va_end(ap);
 return p;
} 

st_info *num(int value) {
 st_info *p;
 if ((p = malloc(sizeof(st_info))) == NULL)
 yyerror("out of memory");
 p->type = typeCon;
 p->num.value = value;
 p->dType = INTEGER;
 return p;
}

st_info *flo(float value) {
 st_info *p;
 if ((p = malloc(sizeof(st_info))) == NULL)
 yyerror("out of memory");
 p->type = typeFlo;
 p->flo.value = value;
 p->dType = DECIMAL;
 return p;
}

st_info *id(char *c) {
 int i = hash(c);
 // printf(c);
//  printf("hash of var: %d\n", i);
 st_info *p;
 if ((p = malloc(sizeof(st_info))) == NULL)
    yyerror("out of memory");
 p->type = typeId;
 p->id.i = i;
 p -> dType = sym[i];
 address[i] -> id.i = i;
 address[i] -> dType = ID;
 return p;
} 
st_info *func(char *c) {
 st_info *p;
 if ((p = malloc(sizeof(st_info))) == NULL)
    yyerror("out of memory");
 int i = hash(c);
 p->type = typeStm;
 p->id.i = i;
 p -> dType = sym[i];
//  address[i] -> id.i = i;
//  address[i] -> dType = FUNCTION_ID;
//  printf("func created");
 return p;
} 

st_info *cls(char *c) {
 st_info *p;
 if ((p = malloc(sizeof(st_info))) == NULL)
    yyerror("out of memory");
 int i = hash(c);
 p->type = typeStm;
 p->id.i = i;
//  printf(c);
//  printf(" %d ", i);
 p -> dType = sym[i];
//  printf("here");
//  address[i] -> id.i = i;
//  address[i] -> dType = FUNCTION_ID;
//  printf("func created");
 return p;
} 
val *process(st_info *p) {
 if (!p) return NULL;
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
    case typeStm:
       switch(p->st_add.oper) {
       case CLASS: {
                      int i = (p -> st_add.op[1]) -> id.i;
                      (p -> st_add.op[1]) -> id.i = p -> st_add.op[0] -> id.i;
                      // address[i] = address[p -> st_add.op[0] -> id.i];
                      // printf(" %d %d ", i, p -> st_add.op[0] -> id.i);
                      return NULL;
                  }
       case GET_VAL: {
                      // printf("here");
                      class_vars* ptr = address[p -> st_add.op[0]->id.i] -> cls_vr;

                      // printf(" %d ", p -> st_add.op[0]->id.i);
                      // printf("%d\n", p -> st_add.op[1]->id.i);

                      if(!ptr){
                        yyerror("No such class");
                      }
                      while(ptr -> var -> id.i != p -> st_add.op[1]->id.i){
                        ptr = ptr -> cls_vr;
                        if(!ptr){
                          yyerror("No such attribute of class");
                        }
                      }
                      // printf("here");
                      ret -> num = ptr -> var -> num.value;
                      ret -> flo = ptr -> var -> flo.value;
                      return ret;
                  }
       case FUNC: {
                    // printf("here ");
                    int h = (p -> st_add.op[0]) -> id.i;
                    // printf("%d ", h);

                    process(address[h]);
                    return NULL;
                  }
       case WHILE: {
                    while(1){
                      val *x = process(p -> st_add.op[0]);
                      if(x -> dType == INTEGER && x -> num == 0) break;
                      if(x -> dType == DECIMAL && x -> flo == 0) break;
                      process(p->st_add.op[1]);
                    }  
                    return NULL;
                  }
       case IF: {
                  val *x = process(p -> st_add.op[0]);
                  if (!((x -> dType == INTEGER && x -> num == 0) || (x -> dType == DECIMAL && x -> flo == 0))){
                      process(p->st_add.op[1]);
                      return NULL;
                  }  
                  else if (p->st_add.nops > 2) {
                    process(p->st_add.op[2]); return NULL;
                  }
              }
       case READ: {
                    printf("Enter Value of Variable: ");
                    float value;
                    scanf("%f", &value);
                    if (value != (int)value){
                      sym[p->st_add.op[0]->id.i] = DECIMAL;
                      symbols[p->st_add.op[0]->id.i] = value;
                    }
                    else{
                      sym[p->st_add.op[0]->id.i] = INTEGER;
                      symbols[p->st_add.op[0]->id.i] = (int)value;
                    }
                    return NULL;
                  }
       case WRITE:  {
                      val *x = process(p -> st_add.op[0]);
                      if(x -> dType == DECIMAL){
                        printf("%f\n", x -> flo); return NULL;
                      }
                      else if(x -> dType == INTEGER) {
                        printf("%d\n", x -> num); return NULL;
                      }
                    }
       case ';': {
                    process(p->st_add.op[0]);  
                    process(p->st_add.op[1]);
                    return NULL;
                 }
       case '=': {
                    if(p->st_add.nops == 2){
                      val *x = process(p->st_add.op[1]);
                    // printf("Hash : %d", p->st_add.op[0]->id.i);
                      sym[p->st_add.op[0]->id.i] = x -> dType;
                      if(x -> dType == DECIMAL) {
                          symbols[p->st_add.op[0]->id.i] = x -> flo;
                      }
                      else if(x -> dType == INTEGER) {
                        symbols[p->st_add.op[0]->id.i] = x -> num;
                      }
                      // printf("here");
                      return NULL;
                    }
                    else{
                      // printf("here");
                      class_vars* ptr = address[p -> st_add.op[0]->id.i] -> cls_vr;

                      // printf(" %d ", p -> st_add.op[0]->id.i);
                      // printf("%d\n", p -> st_add.op[1]->id.i);
                      // printf("here\n");

                      if(!ptr){
                        yyerror("No such class");
                      }
                      while(ptr -> var -> id.i != p -> st_add.op[1]->id.i){
                        ptr = ptr -> cls_vr;
                        if(!ptr){
                          yyerror("No such attribute of class");
                        }
                      }
                      // printf("here\n");
                      // printf(" %d ", p->st_add.op[2] ->num.value);
                      ptr -> var -> num.value = p->st_add.op[2] ->num.value;
                      ptr -> var -> flo.value = p->st_add.op[2] ->flo.value;
                      return NULL;
                    }

                 }
       case UMINUS: {
                      val *x = process(p->st_add.op[0]);
                      x -> flo = - x -> flo;
                      x -> num = - x -> num;
                      return x;
                    }
       case '+': {
                    val *l = process(p->st_add.op[0]);
                    val *r = process(p->st_add.op[1]);
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
                    val *l = process(p->st_add.op[0]);
                    val *r = process(p->st_add.op[1]);
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
                    val *l = process(p->st_add.op[0]);
                    val *r = process(p->st_add.op[1]);
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
                    val *l = process(p->st_add.op[0]);
                    val *r = process(p->st_add.op[1]);
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
                    val *l = process(p->st_add.op[0]);
                    val *r = process(p->st_add.op[1]);
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
                    val *l = process(p->st_add.op[0]);
                    val *r = process(p->st_add.op[1]);
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
                    val *l = process(p->st_add.op[0]);
                    val *r = process(p->st_add.op[1]);
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
                  exit(1);
                  }

   }
  }
  return 0;
} 

