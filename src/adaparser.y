/******************************************************************************
 *
 * 
 *
 * Copyright (C) 2016 by Herman Lundkvist.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation under the terms of the GNU General Public License is hereby 
 * granted. No representations are made about the suitability of this software 
 * for any purpose. It is provided "as is" without express or implied warranty.
 * See the GNU General Public License for more details.
 *
 * Documents produced by Doxygen are derivative works derived from the
 * input used in their production; they are not affected by this license.
 *
 */

%{
#include <qfileinfo.h>
#include <stdlib.h>
#include <stdio.h>
#include <iostream>

#include <list>
#include <algorithm>

#include "util.h"
#include "entry.h"
#include "types.h"
#include "arguments.h"
#include "adaparser.h"
#include "adacommon.h"
#include "adarulehandler.h"
#include "filedef.h"

#define YYDEBUG 1

//from flex for bison to know about!
extern int adaYYlex();
extern int adaYYparse();
extern int adaYYwrap();
extern void adaYYrestart( FILE *new_file );
void adaYYerror (char const *s);

/** \brief type of values moved between flex and bison. */
typedef union ADAYYSTYPE_{
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
}ADAYYSTYPE_;
#define ADAYYSTYPE ADAYYSTYPE_

static Node *s_root;
static RuleHandler *s_handler;

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
%token <nodePtr>SPECIAL_COMMENT
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
%type<nodePtr> doxy_comment
%type<nodePtr> package_spec
%type<nodePtr> package_spec_base
%type<nodePtr> package_decl
%type<nodePtr> subprogram_spec
%type<nodePtr> subprogram_spec_base
%type<nodePtr> subprogram_decl
%type<nodePtr> body
%type<nodePtr> package_body
%type<nodePtr> package_body_base
%type<nodePtr> subprogram_body
%type<nodesPtr> basic_decls
%type<nodesPtr> decls
%type<nodesPtr> obj_decl
%type<nodesPtr> obj_decl_base
%type<nodePtr> decl_item
%type<nodesPtr> decl_items
%type<idsPtr> identifier_list
%type<nodePtr> library_item
%type<nodePtr> library_item_decl
%type<nodePtr> library_item_body
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
         s_handler->addToRoot($1);
       }

/* TODO: add error handling */
doxy_comment: SPECIAL_COMMENT

library_item: library_item_decl| library_item_body

library_item_decl: package_decl| subprogram_decl

library_item_body: package_body| subprogram_body


package_decl:      package_spec SEM{$$ = $1;}
package_spec:      package_spec_base
                   |doxy_comment package_spec_base
                     {$$ = s_handler->packageSpec($2, $1);}
package_spec_base: PACKAGE IDENTIFIER IS
                   basic_decls END
                    IDENTIFIER
                      {
                       $$ = s_handler->packageSpecBase($2, $4);
                       delete $6;
                      }
                    | PACKAGE IDENTIFIER IS basic_decls
                      PRIVATE basic_decls END IDENTIFIER
                      {
                       $$ = s_handler->packageSpecBase($2, $4, $6);
                       delete $8;
                      }

subprogram_decl:   subprogram_spec SEM {$$ = $1;}
subprogram_spec:   subprogram_spec_base|
                   doxy_comment subprogram_spec_base
                     {s_handler->subprogramSpec($2, $1);
                      $$ = $2;}
subprogram_spec_base:  PROCEDURE IDENTIFIER
                   {
                     $$ = s_handler->subprogramSpecBase($2);
                   }
                   |PROCEDURE IDENTIFIER
                    LPAR parameters RPAR
                   {
                     $$ = s_handler->subprogramSpecBase($2, $4);
                   }
                   |FUNCTION IDENTIFIER RETURN
                    IDENTIFIER
                   {
                     $$ = s_handler->subprogramSpecBase($2, NULL, $4);
                   }
                   |FUNCTION IDENTIFIER
                    LPAR parameters RPAR RETURN
                    IDENTIFIER
                   {
                     $$ = s_handler->subprogramSpecBase($2, $4, $7);
                   }
body:              package_body| subprogram_body
package_body:      package_body_base
                   |doxy_comment package_body_base
                     {s_handler->packageBody($2, $1);
                      $$ = $2;}
package_body_base: PACKAGE_BODY IDENTIFIER IS
                   END IDENTIFIER SEM
                   {
                     $$ = s_handler->packageBodyBase($2); 
                     delete $5;
                   }
                   |PACKAGE_BODY IDENTIFIER IS
                   decls END IDENTIFIER SEM
                   {
                     $$ = s_handler->packageBodyBase($2, $4); 
                     delete $6;
                   }
                   |PACKAGE_BODY IDENTIFIER IS
                   decls BEGIN_ statements END SEM
                   {
                     $$ = s_handler->packageBodyBase($2, $4); 
                   }

subprogram_body:  subprogram_spec IS
                  BEGIN_ statements END tail
                  |subprogram_spec IS decls
                  BEGIN_ statements END tail
tail:             SEM| IDENTIFIER SEM {delete $1;}

parameters:       parameter_spec
                  | parameter_specs parameter_spec
                   {$$ = s_handler->params($1, $2);}
parameter_specs:  parameter_spec SEM {$$ = $1;}
                  |parameter_specs parameter_spec SEM
                   {$$ = s_handler->params($1, $2);}
parameter_spec:    identifier_list COLON subtype
                     {$$ = s_handler->paramSpec($1, $3);}
                   |identifier_list COLON mode subtype
                     {$$ = s_handler->paramSpec($1, $4, $3);}

mode:              IN {$$ = new QCString("in");}
                   | OUT {$$ = new QCString("out");}
                   | IN OUT {$$ = new QCString("in out");}

decls:             body {$$ = s_handler->declsBase($1);}
                   |decl_item {$$ = s_handler->declsBase($1);}
                   |decl_items {$$ = s_handler->declsBase($1);}
                   |decls body {$$ = s_handler->decls($1, $1);}
                   |decls decl_item {$$ = s_handler->decls($1, $2);}
                   |decls decl_items {$$ = s_handler->decls($1, $2);}

basic_decls:        decl_items {$$ = s_handler->declsBase($1);}
                    |decl_item {$$ = s_handler->declsBase($1);}
                    |basic_decls decl_items
                    {$$ = s_handler->decls($1, $2);}
                    |basic_decls decl_item
                    {$$ = s_handler->decls($1, $2);}

decl_items:         obj_decl
decl_item:          subprogram_decl| package_decl

obj_decl:           obj_decl_base
                    |doxy_comment obj_decl_base
                    {$$ = s_handler->objDecl($2, $1);}
obj_decl_base:      identifier_list COLON 
                    subtype expression SEM
                    {$$ = s_handler->objDeclBase($1, $3);}
                     
                      /* move to handlers */
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
                    
                    /* move to handlers */
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

void AdaLanguageScanner::parseInput(const char * fileName, 
                const char *fileBuf, 
                Entry *root,
                bool sameTranslationUnit,
                QStrList &filesInSameTranslationUnit)
{
  std::cout << "ADAPARSER" << std::endl;
  EntryHandler eh(root);
  s_handler = &eh;
  qcFileName = fileName;
  yydebug = 1;


  inputFile.setName(fileName);

  if (inputFile.open(IO_ReadOnly))
  {
    initAdaScanner(this, fileName, root);
    setInputString(fileBuf);
    adaYYparse();
    cleanupInputString();
    inputFile.close();
    eh.addFileSection(fileName);
  }
  s_root->print();
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
  /* CHECK IF CAN REMOVE THIS */
  //initAdaScanner(this, fileDef->name(), root);
  CodeHandler ch;
  s_handler = &ch;
  setInputString(input);
  adaYYparse();
  cleanupInputString();

  //printNodeTree(*s_root);

  /* Clean up static variables */
  //s_nodes_mem.clear();
  //s_symbols_mem.clear();
  //s_root = NULL;
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
