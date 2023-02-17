typedef enum { typeCon, typeFlo, typeId, typeOpr } nodeEnum;
typedef enum { INTEGER, DECIMAL, CHARACTER} dataType;
const char* dArr[] = {"INTEGER", "DECIMAL", "CHARACTER"};
typedef struct {
 int value;
} conNodeType;

typedef struct {
 float value;
} floNodeType;

typedef struct {
 int i; 
} idNodeType;

typedef struct {
 int oper; 
 int nops; 
 struct nodeType **op; 
} oprNodeType;

struct nodeType {
 nodeEnum type; /* type of node */
 dataType dType;
 conNodeType num; /* constants */
 floNodeType flo; /*floating constants */
 idNodeType id; /* identifiers */
 oprNodeType opr; /* operators */
};

typedef struct val {
	dataType dType;
	int num;
	float flo;
} val;
typedef struct nodeType NodeType;