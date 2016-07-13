%{
#include <iostream>
#include <stdlib.h>
#include <stdio.h>
#include <list>
#include <vector>

#include <qfileinfo.h>
#include <qlist.h>
#include <qcstring.h>

#include "entry.h"
#include "adaparser.h"
#include "dbg_util.h"
#include "message.h"
#define YYDEBUG 1

enum NodeType
{
  ADA_PKG,
  ADA_VAR,
  ADA_SUBPROG
};

//from flex for bison to know about!
extern int adaYYlex();
extern int adacodeYYparse();
int adacodeYYwrap();
int adacodeYYlex();
void adacodeYYrestart( FILE *new_file );
void adacodeYYerror (char const *s);

/** \brief an entity that needs to be linked.
 *
 * stores data needed to compute
 * links between entities.*/
struct Node
{
  NodeType type;
  QCString name;
  QCString name_space;
  std::list<Node*> references;
};


/** \brief a struct for marking special syntax symbols
 *
 * Contains a location of the symbol and how the
 * symbol should be handeled.
 */
struct syntaxSymbol
{
  int line_n;
  int col;
};

typedef std::list<Node*> Nodes;
typedef Nodes::iterator NodesIter;
typedef std::list<syntaxSymbol> SyntaxSymbols;
typedef SyntaxSymbols::iterator SyntaxSymbolsIter;

/* Statics */
static std::vector<Node> s_nodes_mem;
static SyntaxSymbols s_symbols_mem;
static Node* s_root;


void printNodeTree(const Node& node, std::string pad="");

static Node* handlePackage(const char* name, Nodes *publics,
                     Nodes *privates=NULL);
static Node* handleSubprogram(const char* name,
                        ArgumentList *args=NULL, const char *type=NULL);
static Nodes *handleDeclsBase(Node *new_entry);
static Nodes *handleDeclsBase(Nodes *new_entries);
static Nodes *handleDecls(Node *new_entry, Nodes *entries);
static Nodes *handleDecls(Nodes *new_entries, Nodes *entries);

static Node *handlePackageBody(const char* name,
                           Nodes *decls=NULL);
%}

%union {
  int intVal;
  char charVal;
  char* cstrVal;
  Node* nodePtr;
  Nodes* nodesPtr;
  Entry* entryPtr;
  QCString* qstrPtr;
  Entries* entriesPtr;
  ArgumentList* argsPtr;
  Identifiers* idsPtr;
}

/*KEYWORDS*/
%token ABORT
%token ABS
%token ABSTRACT //ADA 95
%token ACCEPT
%token ACCESS
%token ALIASED //ADA 95
%token ALL
%token AND
%token ARRAY
%token AT
%token BEGIN_ causes conflict with begin macro
%token CASE
%token CONSTANT
%token DECLARE
%token DELAY
%token DELTA
%token DIGITS
%token DO
%token ELSE
%token ELSIF
%token END
%token ENTRY
%token EXCEPTION
%token EXIT
%token FUNCTION
%token GENERIC
%token GOTO
%token IF
%token IN
%token INTERFACE //ADA 2005
%token <cstrVal>IDENTIFIER
%token IS
%token LIMITED
%token LOOP
%token MOD
%token NEW
%token NOT
%token Null
%token OF
%token OR
%token OTHERS
%token OUT
%token OVERRIDING //ADA 2005
%token PACKAGE
%token PACKAGE_BODY
%token PRAGMA
%token PRIVATE
%token PROCEDURE
%token PROTECTED // ADA 95
%token RAISE
%token RANGE
%token RECORD
%token REM
%token RENAMES
%token REQUEUE //ADA 95
%token RETURN
%token REVERSE
%token SELECT
%token SEPARATE
 //%token SOME (ADA 2012)
%token SUBTYPE
%token SYNCHRONIZED //ADA 2005
%token TAGGED //ADA 95
%token TASK
%token TERMINATE
%token THEN
%token TYPE
%token UNTIL //ADA 95
%token USE
%token WHEN
%token WHILE
%token WITH
%token XOR

 /*OTHER */
%token START_COMMENT
%token START_DOXY_COMMENT
%token <cstrVal>COMMENT_BODY
%token <entryPtr>SPECIAL_COMMENT
%token LINE
%token NEWLINE
%token TIC
%token DDOT
%token MLT
%token BOX
%token LTEQ
%token EXP
%token NEQ
%token MGT
%token GTEQ
%token ASS
%token REF
%token SEM
%token COMMA
%token COLON
%token LPAR
%token RPAR

/*non-terminals*/
%type<entryPtr> doxy_comment
/*%type<nodePtr> package_spec
%type<nodePtr> package_spec_base
%type<nodePtr> package_decl*/
%type<nodePtr> subprogram_spec
%type<nodePtr> subprogram_spec_base
%type<nodePtr> subprogram_decl
/*%type<entryPtr> body*/
/*%type<nodePtr> package_body
%type<nodePtr> package_body_base
%type<nodePtr> subprogram_body
%type<nodesPtr> basic_decls
%type<nodesPtr> decls
%type<nodesPtr> obj_decl
%type<nodesPtr> obj_decl_base
%type<nodePtr> decl_item
%type<nodesPtr> decl_items
*/
%type<idsPtr> identifier_list
%type<nodePtr> library_item
%type<nodePtr> library_item_decl
/*%type<nodePtr> library_item_body*/
%type<qstrPtr> subtype
%type<argsPtr> parameter_spec
%type<argsPtr> parameter_specs
%type<argsPtr> parameters
%type<qstrPtr> mode
 
%defines 
/*
 NOTE: when receiving c strings from the lexer, the parser
 becomes responsible for deallocating them. Thus, they
 need to be deleted in every rule that they are used.
*/
%%
start: library_item
       {
         s_root = $1;
       }

/* TODO: add error handling */
doxy_comment: SPECIAL_COMMENT{
                     std::cout << "comment: " << $1->doc << std::endl;}

library_item: library_item_decl/*| library_item_body*/

library_item_decl:  subprogram_decl/*| package_decl*/

/*library_item_body:  subprogram_body| package_body*/

/*
package_spec_base: PACKAGE IDENTIFIER IS
                   basic_decls END
                    IDENTIFIER
                      {
                       delete $6;
                      }
                    | PACKAGE IDENTIFIER IS basic_decls
                      PRIVATE basic_decls END IDENTIFIER
                      {
                       $$ = handlePackage($2, $4, $6);
                       delete $8;
                      }
                      */
subprogram_decl:   subprogram_spec SEM {$$ = $1;}
subprogram_spec:   subprogram_spec_base|
                   doxy_comment subprogram_spec_base
                     {$$ = $2;}
subprogram_spec_base:  PROCEDURE IDENTIFIER
                   {$$ = handleSubprogram($2);}
                   |PROCEDURE IDENTIFIER
                    LPAR parameters RPAR
                   {$$ = handleSubprogram($2, $4);}
                   |FUNCTION IDENTIFIER RETURN
                    IDENTIFIER
                   {
                     $$ = handleSubprogram($2, NULL, $4);
                   }
                   |FUNCTION IDENTIFIER
                    LPAR parameters RPAR RETURN
                    IDENTIFIER
                   {
                     $$ = handleSubprogram($2, $4, $7);
                   }
/*
body:              package_body {$$ = $1;}
                   |subprogram_body {$$ = $1;}

package_body:      package_body_base
                   |doxy_comment package_body_base
                     {addDocToEntry($1, $2);
                      $$ = $2;}
package_body_base: PACKAGE_BODY IDENTIFIER IS
                   END IDENTIFIER SEM
                   {
                     $$ = handlePackageBody($2); 
                   }
                   |PACKAGE_BODY IDENTIFIER IS
                   decls END IDENTIFIER SEM
                   {
                     $$ = handlePackageBody($2, $4); 
                   }
                   |PACKAGE_BODY IDENTIFIER IS
                   decls BEGIN_ statements END SEM
                   {
                     $$ = handlePackageBody($2, $4); 
                   }

subprogram_body:  subprogram_spec IS
                  BEGIN_ statements END tail
                  {
                    $$ = $1;
                  }
                  |subprogram_spec IS decls
                  BEGIN_ statements END tail
                  {
                    $$ = $1;
                  }
tail:             SEM| IDENTIFIER SEM {delete $1;}
    */
    

parameters:       parameter_spec
                  | parameter_specs parameter_spec
                   {$$ = handleParams($1, $2);}
parameter_specs:  parameter_spec SEM {$$ = $1;}
                  |parameter_specs parameter_spec SEM
                   {$$ = handleParams($1, $2);}
parameter_spec:    identifier_list COLON subtype
                     {$$ = handleParamSpec($1, $3);}
                   |identifier_list COLON mode subtype
                     {$$ = handleParamSpec($1, $4, $3);}

mode:              IN {$$ = new QCString("in");}
                   | OUT {$$ = new QCString("out");}
                   | IN OUT {$$ = new QCString("in out");}

/*
decls:             body {$$ = handleDeclsBase($1);}
                   |decl_item {$$ = handleDeclsBase($1);}
                   |decl_items {$$ = handleDeclsBase($1);}
                   |decls body {$$ = handleDecls($1, $1);}
                   |decls decl_item {$$ = handleDecls($1, $1);}
                   |decls decl_items {$$ = handleDecls($1, $1);}

basic_decls:        decl_items {$$ = handleDeclsBase($1);}
                    |decl_item {$$ = handleDeclsBase($1);}
                    |basic_decls decl_items{$$ = handleDecls($2, $1);}
                    |basic_decls decl_item{$$ = handleDecls($2, $1);}

decl_items:         obj_decl
decl_item:          subprogram_decl| package_decl

obj_decl:           obj_decl_base
                    |doxy_comment obj_decl_base
                    {
                      Entries *es = $2;
                      if (!es->empty())
                        addDocToEntry($1, es->back());
                      $$ = es;
                    }
obj_decl_base:      identifier_list COLON 
                    subtype expression SEM
                    {
                      Entries *entries = new Entries;

                      Identifiers *ids = $1;
                      QCString *type = $3;
                      IdentifiersIter it = ids->begin();
                      for (;it != ids->end(); ++it)
                      {
                        Entry *e = newEntry();
                        e->name = (*it);
                        e->type = *type;
                        e->section = Entry::VARIABLE_SEC;
                        entries->push_front(e);
                      }

                      $$ = entries;
                      delete type;;
                      delete ids;
                    }
                    */
identifier_list:    IDENTIFIER
                    {
                      QCString id = $1;
                      std::cout << "New id " << id << std::endl;
                      Identifiers *ids = new Identifiers;
                      ids->push_front(id);

                      printf("identifier list\n");
                      $$ = ids;
                      delete $1;
                    }
                    |IDENTIFIER COMMA identifier_list
                    {
                      std::cout << "New id " << $1 << std::endl;
                      Identifiers *ids = $3;
                      ids->push_front(QCString($1));

                      $$ = ids;
                      delete $1;
                    }
                    
subtype:            IDENTIFIER constraint
                    {
                      std::cout << "New type " << $1 << std::endl;
                      $$ = new QCString($1);
                      delete $1;
                    }
/*statements: statements statement| statement
statement:  null_statement;
null_statement: Null SEM;
              */
constraint:;
/*expression:;*/

%%

void printNodeTree(const Node& node, std::string pad)
{
  msg("%s====================\n", pad.data());
  msg("%sNODE:\n", pad.data());
  msg("%ssection: %s", pad.data(), section2str(node.type).data()); 
  printQC(pad, "name", node.name);
  printQC(pad, "namespace", node.name_space.data());
  msg("%sCHILDREN:\n", pad.data());

  pad +=  "    "; 
  std::list<Node*>::const_iterator it = node.references.begin();
  for (; it!=node.references.end(); ++it)
  {
    printNodeTree(*(*it), pad);
  }
  
}

Node* handlePackage(const char* name, Nodes *publics,
                     Nodes *privates)
{
  Node n;
  n.name = name;
  n.type = ADA_PKG;
  
  n.references.splice(n.references.end(), *publics);

  if (privates)
    n.references.splice(n.references.end(), *privates);

  delete name;
  s_nodes_mem.push_back(n);
  return &s_nodes_mem.back();
}

Node* handleSubprogram(const char* name,
                        ArgumentList *args, const char *type)
{
  Node n;
  n.name = name;
  n.type = ADA_SUBPROG;

  Argument *arg;
  ArgumentListIterator it(*args);
  it.toFirst();
  for (; (arg=it.current()); ++it )
  {
    Node var;
    var.type = ADA_VAR;
    var.name = arg->name;
    n.references.push_back(&var);
  }

  delete name;
  s_nodes_mem.push_back(n);
  return &s_nodes_mem.back();
}

void AdaLanguageScanner::parseCode(CodeOutputInterface &codeOutIntf,
                   const char *scopeName,
                   const QCString &input,
                   SrcLangExt lang,
                   bool isExampleBlock,
                   const char *exampleName,
                   FileDef *fileDef,
                   int startLine,
                   int endLine,
                   bool inlineFragment,
                   MemberDef *memberDef,
                   bool showLineNumbers,
                   Definition *searchCtx,
                   bool collectXrefs
                  )
{
  std::cout << "ADA CODE PARSER" << std::endl;

  setInputString(input);
  adacodeYYparse();
  cleanupInputString();

  printNodeTree(*s_root);

  /* Clean up static variables */
  s_nodes_mem.clear();
  s_symbols_mem.clear();
  s_root = NULL;
}

//called when yylex reaches end of file, returns 1 to stop yylex from continuing scan
int adacodeYYwrap()
{
  return 1;
}

//for printing errors and type of error when encountered
void adacodeYYerror(const char *s)
{
  printf("ERROR: ada parser\n");
}

int adacodeYYlex()
{
  adaYYlex();
}
