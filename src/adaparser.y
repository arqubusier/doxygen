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
void initEntry (Entry *e, Entry *parent=NULL, Protection prot=Public,
                MethodTypes mtype=Method, bool stat=false,
                Specifier virt=Normal);

static Entry* s_root;
static AdaLanguageScanner* s_adaScanner;
 %}

%union {
  int intVal;
  char charVal;
  char* cstrVal;
  Entry* entryPtr;
  QCString* qstrPtr;
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
%token BEGIN
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

 /*OTHER */
%token START_COMMENT
%token START_DOXY_COMMENT
%token <cstrVal>COMMENT_BODY
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

/*non-terminals*/
//%type<charVal> character_literal
//%type<cstrVal> identifier
//%type<intVal> numerical
//%type<entryPtr> package_spec
//%type<entryPtr> package_body
//%type<cstrVal> comment
%type<entryPtr> doxy_comment
%type<qstrPtr> doxy_comment_cont


%defines

%%

start: doxy_comment {s_root->addSubEntry($1);}

doxy_comment:       COMMENT_BODY doxy_comment_cont
                    {QCString doc = QCString($1) + *$2;
                     std::cout << "comment: " << doc << std::endl; 
                     delete $1;
                     delete $2;
                     Entry *e = new Entry;
                     initEntry(e);
                     s_adaScanner->handleComment(e, doc);
                     $$ = e;}

doxy_comment_cont:  /*COMMENT_BODY doxy_comment_cont
                 
                      {Entry* e = new QCString(QCString($1) + *$2);
                       delete $1;
                       delete $2;
                       $$ = e;}
                       
                    |*/ {$$ = new QCString("");}

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

void AdaLanguageScanner::handleComment(Entry* comment_root, const QCString &doc)
{
  int pos=0;
  int lineNum=0;
  Protection protection = Public;
  bool newEntryNeeded;
  Entry *current;

  while (parseCommentBlock(
           this,
           current,
           doc,
           qcFileName,
           lineNum,
           false,
           false,
           false,
           protection,
           pos,
           newEntryNeeded))
  {
    if (newEntryNeeded){
      current = new Entry;
      comment_root->addSubEntry(current);
    }
  }
  if (newEntryNeeded){
    current = new Entry;
    comment_root->addSubEntry(current);
  }
}

void AdaLanguageScanner::parseInput(const char * fileName, 
                const char *fileBuf, 
                Entry *root,
                bool sameTranslationUnit,
                QStrList &filesInSameTranslationUnit){
  std::cout << "ADAPARSER" << std::endl;
  s_root = root;
  s_adaScanner = this;
  qcFileName = fileName;

  inputFile.setName(fileName);

  if (inputFile.open(IO_ReadOnly))
  {
    setInputString(fileBuf);
    adaYYparse();
    cleanupInputString();
    inputFile.close();
  }
  s_root->printTree();
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

void adaFreeScanner(){;}
