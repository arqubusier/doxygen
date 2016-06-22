%{
#include <qfileinfo.h>
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include "adaparser.h"
#include "entry.h"
#include "types.h"
#include "commentscan.h"

  //from flex for bison to know about!
extern int adaYYlex();
extern int adaYYparse();
extern int adaYYwrap();
extern void adaYYrestart( FILE *new_file );
void adaYYerror (char const *s);
void initEntry (Entry *e, Protection prot, MethodTypes mtype, bool stat,
                Specifier virt, Entry *parent);
 %}

%union {
  int intVal;
  char charVal;
}

%token <charVal>CHARACTER

/*KEYWORDS*/
/*
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
%token BeGIN
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
%token FOR
%token FUNCTION
%token GENERIC
%token GOTO
%token IF
%token IN
%token INTERFACE //ADA 2005
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
*/

 /*OTHER */
/*
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
*/ 

/*non-terminals*/
/*%token string_literal
%token character_literal
%token identifier
%token numerical
*/
adaYYin
%%

start: test
test: /* empty */
        {std::cout << "adaparser end found" << std::endl;}
      | test CHARACTER
        {std::cout<< "adaparser found: " << $2 <<std::endl;}
%%

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
                QStrList &filesInSameTranslationUnit){
  std::cout << "ADAPARSER" << std::endl;

  qcFileName = fileName;

  //root = new Entry;
  //root->section = Entry::EMPTY_SEC;
  //initEntry(root, Public, Method, false, Normal, root);

  inputFile.setName(fileName);

if (inputFile.open(IO_ReadOnly))
  {
    setInputString(fileBuf);
    adaYYparse();
    cleanupInputString();
    inputFile.close();
  }
  Entry *e = new Entry();
  e->section = Entry::NAMESPACE_SEC;
  e->name = "A";
  e->type = "namespace";
  initEntry(e, Public, Method, false, Normal, root);
  root->addSubEntry(e);

  Entry *e2 = new Entry();
  initEntry(e2, Public, Method, false, Normal, e);

  QCString doc = QCString("\\file test.adb \n brief... det..");  
  int pos=0;
  int lineNum=0;
  Protection protection = Public;
  bool newEntryNeeded;
  parseCommentBlock(
    this,
    e2,
    doc,
    qcFileName,
    lineNum,
    false,
    false,
    false,
    protection,
    pos,
    newEntryNeeded);

  e->addSubEntry(e2);

  /*
  e2->section = Entry::FILEDOC_SEC;
  e2->name = "test.adb";
  e2->brief = "Documentation for test.adb";
  e->addSubEntry(e2);

  Entry *e3 = new Entry();
  e3->name = "B";
  e3->section = Entry::USINGDECL_SEC;
  e2->addSubEntry(e3);

  e2 = new Entry();
  e2->section = Entry::NAMESPACE_SEC;
  e2->name = "B";
  e->addSubEntry(e2);
  */
  root->printTree();
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

void initEntry (Entry *e, Protection prot, MethodTypes mtype, bool stat,
                Specifier virt, Entry *parent)
{
  e->protection = prot;
  e->mtype      = mtype;
  e->virt       = virt;
  e->stat       = stat;
  e->lang       = SrcLangExt_Ada; 
  e->setParent(parent);
}

void adaFreeScanner(){;}
