%{
#include <qfileinfo.h>
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include "adaparser.h"
#include "entry.h"
#include "types.h"
#include "arguments.h"
#include <list>
#include <algorithm>

//from flex for bison to know about!
extern int adaYYlex();
extern int adaYYparse();
extern int adaYYwrap();
extern void adaYYrestart( FILE *new_file );
void adaYYerror (char const *s);
extern Entries structuralEntries;
void initEntry (Entry *e, Entry *parent=NULL, Protection prot=Public,
                MethodTypes mtype=Method, bool stat=false,
                Specifier virt=Normal);
Entry* handlePackage(const char* name, Entries *publics,
                     Entries *privates=NULL);
Entry* handleSubprogram(const char* name,
                        ArgumentList *args=NULL, const char *type=NULL);
Entries *handleDeclsBase(Entry *new_entry);
Entries *handleDeclsBase(Entries *new_entries);
Entries *handleDecls(Entry *new_entry, Entries *entries);
Entries *handleDecls(Entries *new_entries, Entries *entries);

Entry *handlePackageBody(const char* name,
                           Entries *decls=NULL);
/**
 * Takes the children from src and adds them to dst.
 * dst parent is removed.
 */
void   moveEntries(Entries *dst_entries, Entries* src_entries); 
void   moveEntriesToEntry(Entry *entry, Entries* entries); 
void   addDocToEntries(Entry* doc, Entries* entries);
void addDocToEntry(Entry *doc, Entry *entry);
Entry* newEntry();

static Entry* s_root;
static AdaLanguageScanner* s_adaScanner;

 %}

%union {
  int intVal;
  char charVal;
  char* cstrVal;
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
%type<entryPtr> package_spec
%type<entryPtr> package_spec_base
%type<entryPtr> package_decl
%type<entryPtr> subprogram_spec
%type<entryPtr> subprogram_spec_base
%type<entryPtr> subprogram_decl
%type<entryPtr> body
%type<entryPtr> package_body
%type<entryPtr> package_body_base
%type<entryPtr> subprogram_body
%type<entriesPtr> basic_decls
%type<entriesPtr> decls
%type<entriesPtr> obj_decl
%type<entriesPtr> obj_decl_base
%type<entryPtr> decl_item
%type<entriesPtr> decl_items
%type<idsPtr> identifier_list
%type<entryPtr> library_item
%type<entryPtr> library_item_decl
%type<entryPtr> library_item_body
%type<qstrPtr> subtype
%type<argsPtr> parameter_spec
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
         Entry *item = $1;
         printf("item %s\n", item->name.data()); 
         s_root->addSubEntry(item);
       }

/* TODO: add error handling */
doxy_comment: SPECIAL_COMMENT{
                     std::cout << "comment: " << $1->doc << std::endl;
                     $$ = $1;}

library_item: library_item_decl| library_item_body

library_item_decl: package_decl| subprogram_decl

library_item_body: package_body| subprogram_body


package_decl:      package_spec SEM{$$ = $1;}
package_spec:      package_spec_base
                   |doxy_comment package_spec_base
                     {addDocToEntry($1, $2);}
package_spec_base: PACKAGE IDENTIFIER IS
                   basic_decls END
                    IDENTIFIER
                      {
                       $$ = handlePackage($2, $4);
                       delete $6;
                      }
                    | PACKAGE IDENTIFIER IS basic_decls
                      PRIVATE basic_decls END IDENTIFIER
                      {
                       $$ = handlePackage($2, $4, $6);
                       delete $8;
                      }

subprogram_decl:   subprogram_spec SEM {$$ = $1;}
subprogram_spec:   subprogram_spec_base|
                   doxy_comment subprogram_spec_base
                     {addDocToEntry($1, $2);}
subprogram_spec_base:  PROCEDURE IDENTIFIER
                   {
                     $$ = handleSubprogram($2);
                   }
                   |PROCEDURE IDENTIFIER
                    LPAR parameters RPAR
                   {
                     $$ = handleSubprogram($2, $4);
                   }
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
body:              package_body {$$ = $1;}
                   |subprogram_body {$$ = $1;}

package_body:      package_body_base
                   |doxy_comment package_body_base
                     {addDocToEntry($1, $2);}
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

parameters:parameter_spec
          |parameter_spec SEM parameters
                   {
                     ArgumentList *args = $3;
                     ArgumentList *new_args = $1;
                     ArgumentListIterator it(*args);
                     Argument *arg;
                     for ( it.toFirst(); (arg=it.current()); ++it )
                     {
                       args->append(arg);
                     }
                     $$ = args;
                     delete new_args;
                   }
parameter_spec:    identifier_list COLON mode subtype
              {
                     ArgumentList *args = new ArgumentList;
                     Identifiers *ids = $1;
                     IdentifiersIter it = ids->begin();
                     QCString *type = $4;
                     QCString *mode = $3;
                     for (; it != ids->end(); ++it)
                     {
                       Argument *a = new Argument;
                       a->type = *type;
                       a->attrib = *mode;
                       a->name = (*it);
                       args->append(a);
                     }
                     $$ = args;
                     delete type;
                     delete mode;
                   }

/* TEST THESE!!! */
mode:              /* empty */ {$$ = new QCString("");}
                   | IN {$$ = new QCString("in");}
                   | OUT {$$ = new QCString("out");}
                   | IN OUT {$$ = new QCString("in out");}

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
statements: statements statement| statement
statement:  null_statement;
null_statement: Null SEM;
constraint:;
expression:;
                    
%%

Entry* newEntry()
{
    Entry* e = new Entry;
    initEntry(e);
    return e;
}

void addDocToEntry(Entry *doc, Entry *entry){
  if( doc ){
    entry->doc = doc->doc;
    entry->brief = doc->brief;
    printf("doc");
  }
  else
    printf("no doc");
}

void   addDocToEntries(Entry *doc, Entries* entries)
{
  if (!entries->empty())
  {
    Entry *entry = entries->back();
    addDocToEntry(doc, entry);
  }
}

void   moveEntries(Entries* dst_entries, Entries* src_entries)
{
  dst_entries->splice(dst_entries->begin(), *src_entries);
  printf("before delete\n");
  delete src_entries;
  printf("after delete\n");
}

void moveEntriesToEntry(Entry* entry, Entries *entries)
{
  EntriesIter it;
  for (it=entries->begin(); it!=entries->end(); ++it)
  {
    entry->addSubEntry(*it);
  } 
  delete entries;
}

Entry *handlePackage(const char* name, Entries *publics,
                     Entries *privates)
{
  printf("New package \n");
  Entry *pkg = newEntry();
  pkg->section = Entry::NAMESPACE_SEC;
  pkg->name = QCString(name);
  pkg->type = QCString("namespace");

  EntriesIter it = publics->begin();
    for (;it != publics->end(); ++it)
      (*it)->protection = Public;

  moveEntriesToEntry(pkg, publics);
  printf("parser: added publics\n");
  if (privates)
  {
    printf("parser: adding privates\n");
    it = privates->begin();
    for (;it != privates->end(); ++it)
      (*it)->protection = Private;
    moveEntriesToEntry(pkg, privates);
  }   

  printf("parser: returning\n");
  delete name;
  return pkg;
}

Entry* handleSubprogram(const char* name,
                        ArgumentList *args, const char *type)
{
  Entry *fun = newEntry();
  fun->name = name;
  delete name;

  if (args)
  {
    fun->argList = args;
  }
  if (type)
  {
    fun->type = type;
    delete type;
  }
  fun->section = Entry::FUNCTION_SEC;
  return fun;
}

Entries *handleDeclsBase(Entry *new_entry)
{
  Entries *es = new Entries;
  es->push_front(new_entry);
  return es;
}

Entries *handleDeclsBase(Entries *new_entries)
{
  Entries *es = new Entries;
  moveEntries(es, new_entries);
  return es;
}

Entries *handleDecls(Entry *new_entry, Entries *entries)
{ 
  entries->push_front(new_entry);
  return entries;
}

Entries *handleDecls(Entries *new_entries, Entries *entries)
{ 
  moveEntries(entries, new_entries);
  return entries;
}


Entry *handlePackageBody(const char* name, Entries *decls)
{
  printf("New package body\n");
  Entry *pkg = newEntry();
  pkg->section = Entry::NAMESPACE_SEC;
  pkg->name = QCString(name);
  pkg->type = QCString("namespace");

  if (decls)
  {
    moveEntriesToEntry(pkg, decls);
  }

  delete name;
  
  return pkg;
}

void addDeclItems(Entry *root){
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
}

void AdaLanguageScanner::parseInput(const char * fileName, 
                const char *fileBuf, 
                Entry *root,
                bool sameTranslationUnit,
                QStrList &filesInSameTranslationUnit)
{
  std::cout << "ADAPARSER" << std::endl;
  s_root = root;
  s_adaScanner = this;
  qcFileName = fileName;


  inputFile.setName(fileName);

  if (inputFile.open(IO_ReadOnly))
  {
    setInputString(fileBuf);
    initAdaScanner(this, qcFileName, s_root);
    adaYYparse();
    cleanupInputString();
    inputFile.close();
  }
  s_root->printTree();
}

void adaFreeScanner()
{
  freeAdaScanner();
}

bool AdaLanguageScanner::needsPreprocessing(const QCString &extension){return false;}
void AdaLanguageScanner::resetCodeParserState(){;}
void AdaLanguageScanner::parsePrototype(const char *text){;}

//called when yylex reaches end of file, returns 1 to stop yylex from continuing scan
int adaYYwrap()
{
  return 1;
}
//for printing errors and type of error when encountered
void adaYYerror(const char *s)
{
  printf("ERROR: ada parser\n");
}

void initEntry (Entry *e, Entry *parent, Protection prot,
                MethodTypes mtype, bool stat,
                Specifier virt)
{
  e->protection = prot;
  e->mtype      = mtype;
  e->virt       = virt;
  e->stat       = stat;
  e->lang       = SrcLangExt_Ada; 
  e->setParent(parent);
}
