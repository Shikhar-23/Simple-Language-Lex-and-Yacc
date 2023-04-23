typedef enum { typeCon, typeFlo, typeId, typeStm} nodeEnum;
typedef enum { INTEGER, DECIMAL, ID, FUNCTION_ID} dataType;
const char* dArr[] = {"INTEGER", "DECIMAL", "ID", "FUNCTION_ID"};
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
 struct st_info **op; 
} oprNodeType;

typedef struct class_vars {
	struct st_info* var;
	struct class_vars *cls_vr;
} class_vars; 

struct st_info {
 nodeEnum type; /* type of node */
 dataType dType;
 conNodeType num; /* constants */
 floNodeType flo; /*floating constants */
 idNodeType id; /* identifiers */
 oprNodeType st_add; /* operators */
 class_vars* cls_vr;
};

typedef struct val {
	dataType dType;
	int num;
	float flo;
} val;
typedef struct st_info st_info;

