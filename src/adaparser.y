%{
#include <qfileinfo.h>
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include "adaparser.h"
#include "entry.h"
#include "types.h"
#include <list>


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

/**
 * Takes the children from src and adds them to dst.
 * dst parent is removed.
 */
void   moveEntries(Entries *dst_entries, Entries* src_entries); 
void   moveEntriesToEntry(Entry *entry, Entries* entries); 
void   addDocToEntries(Entry* doc, Entries* entries);
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
//%token BEGIN causes conflict with begin macro
%token BODY 
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

/*non-terminals*/
//%type<charVal> character_literal
//%type<intVal> numerical
//%type<entryPtr> package_body
%type<entryPtr> doxy_comment
//%type<qstrPtr> doxy_comment_cont
%type<entryPtr> package_spec
%type<entriesPtr> basic_decls
%type<entriesPtr> obj_decl
%type<entriesPtr> decl_item
%type<entriesPtr> identifier_list
%type<entryPtr> library_item
%type<qstrPtr> subtype

%defines
/*
 NOTE: when receiving c strings from the lexer, the parser
 becomes responsible for deallocating them. Thus, they
 need to be deleted in every rule that they are used.
*/
%%

start: doxy_comment library_item
                    {
                     Entry *item = $2;
                     printf("item %s\n", item->name.data()); 
                     s_root->addSubEntry(item);
                     Entry *comment = $1;
                     if ( comment )
                     {
                       s_root->addSubEntry(comment);
                     }
                    }

library_item: package_spec

/* TODO: add error handling */
doxy_comment:       /* empty */ {$$ = NULL;}
                    |SPECIAL_COMMENT
                    {
                     std::cout << "comment: " << $1->doc << std::endl;
                     $$ = $1;}

package_spec:       PACKAGE IDENTIFIER IS basic_decls END
                    IDENTIFIER SEM
                      {
                       $$ = handlePackage($2, $4);
                       printf("p:pub package2\n");
                       delete $2;
                       printf("p:pub package1\n");
                       delete $6;
                       printf("p:pub package2\n");
                      }
                    | PACKAGE IDENTIFIER IS basic_decls
                      PRIVATE basic_decls END IDENTIFIER SEM
                      {
                       $$ = handlePackage($2, $4, $6);
                       delete $2;
                       delete $8;
                      }
basic_decls:        {Entries *entries = new Entries;
                     $$ = entries;
                     printf("new basic_decls root");}
                    |decl_item basic_decls
                    {
                      Entries *entries = $2;
                      Entries *sub_entries = $1;
                      printf("decls\n");
                      moveEntries(entries, sub_entries);
                      printf("decls moved\n");
                      $$ = entries;
                    }
decl_item:          obj_decl
obj_decl:           doxy_comment identifier_list COLON 
                    subtype expression SEM
                    {
                      Entries *entries = $2;
                      addDocToEntries($1, entries);
                      $$ = entries;
                      delete $4;
                    }
identifier_list:    IDENTIFIER
                    {
                      std::cout << "New id " << $1 << std::endl;
                      Entries *entries = new Entries;

                      Entry *obj = newEntry();
                      obj->name = QCString($1);
                      obj->section = Entry::VARIABLE_SEC;
                      obj->type = "int";

                      entries->push_front(obj);
                      printf("identifier list\n");
                      $$ = entries;
                      delete $1;
                    }
                    |IDENTIFIER COMMA identifier_list
                    {
                      std::cout << "New id " << $1 << std::endl;
                      Entries *entries = $3;

                      Entry *obj = newEntry();
                      obj->name = QCString($1);
                      obj->section = Entry::VARIABLE_SEC;
                      obj->type = "int";

                      entries->push_front(obj);

                      $$ = entries;
                      delete $1;
                    }
                    
subtype:            IDENTIFIER constraint
                    {
                      std::cout << "New type " << $1 << std::endl;
                      $$ = new QCString($1);
                      delete $1;
                    }
constraint:;
expression:;
                    
%%

Entry* newEntry()
{
    Entry* e = new Entry;
    initEntry(e);
    return e;
}

void   addDocToEntries(Entry *doc, Entries* entries)
{
  if (!entries->empty() && doc)
  {
    Entry *entry = entries->front();
    entry->doc = doc->doc;
    entry->brief = doc->brief;
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

  moveEntriesToEntry(pkg, publics);
  printf("parser: added publics\n");
  if (privates)
  {
    printf("parser: adding privates\n");
    moveEntriesToEntry(pkg, privates);
  }   

  printf("parser: returning\n");
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
