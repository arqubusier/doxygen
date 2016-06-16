%{
#include<stdlib.h>
#include<stdio.h>
#include <iostream>
#include "adaparser.h"
  //from flex for bison to know about!
extern int adaYYlex();
extern int adaYYparse();
extern FILE *adaYYin;
extern int adaYYwrap();
void adaYYerror (char const *s);
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

%%

test: CHARACTER {
          std::cout<< "adaparser found: " << $1 <<std::endl;}
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
	adaYYparse();
}


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
