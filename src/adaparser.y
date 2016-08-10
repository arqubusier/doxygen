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
#include "message.h"
#include "namespacedef.h"
#include "classdef.h"
#include "doxygen.h"

#define YYDEBUG 1
#define NEW_ID(VAL, LOC) Identifier(VAL, LOC.first_line, LOC.first_column)

//from flex for bison to know about!
extern int adaYYlex();
extern int adaYYparse();
extern int adaYYwrap();
extern void adaYYrestart( FILE *new_file );
void adaYYerror (char const *s);

static FileDef *s_sourceFile;

/**
 * \brief identify references in a CodeNode tree.
 */
void addCrossRef(CodeNode *root, QCString scope="");

static RuleHandler *s_handler;

 %}

%union {
  int intVal;
  char charVal;
  char* cstrVal;
  Entry* entryPtr;
  QCString* qstrPtr;
  Identifier* idPtr;
  Entries* entriesPtr;
  ArgumentList* argsPtr;
  Identifiers* idsPtr;
  Node* nodePtr;
  Nodes* nodesPtr;
  Expression* exprPtr;
  Parameters *paramsPtr;
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
%token FOR
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
%token PIPE
%token LINE
%token NEWLINE
%token TIC
%token DDOT
%token DOT
%token MLT
%token BOX
%token EQ
%token LTEQ
%token EXP
%token NEQ
%token MGT
%token GTEQ
%token LT
%token GT
%token ASS
%token REF
%token SEM
%token COMMA
%token COLON
%token LPAR
%token RPAR
%token ADD
%token MUL
%token MINUS
%token AMB
%token DIV
%token <qstrPtr>INTEGER
%token <qstrPtr>DECIMAL_LITERAL
%token <qstrPtr>BASED_LITERAL
%token <qstrPtr>STRING_LITERAL

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
%type<exprPtr> type
%type<qstrPtr> subtype
%type<exprPtr> array_type
%type<paramsPtr> parameter_spec
%type<paramsPtr> parameter_specs
%type<paramsPtr> parameters
%type<qstrPtr> mode
%type<exprPtr> expression
%type<exprPtr> primary
%type<idsPtr> statement
%type<idsPtr> statements
%type<qstrPtr> expression_sep
/*%type<exprPtr> function_call*/
%type<exprPtr> call_params
%type<exprPtr> param_assoc
%type<qstrPtr> logical
%type<qstrPtr> operator
%type<qstrPtr> relational
%type<qstrPtr>literal
%type<idsPtr> compound
%type<qstrPtr> library_name
%type<exprPtr> array_subtype_definitions
%type<exprPtr> array_subtype_definition
%type<exprPtr> range
%type<exprPtr> range_attribute
/*%type<exprPtr> discrete_subtype*/
%type<exprPtr> discrete_choice_list
%type<exprPtr> discrete_choice
%type<idsPtr> loop_statement
%type<idsPtr> case_statement
%type<idsPtr> case
%type<idsPtr> cases
%type<idsPtr> if_statement
%type<idsPtr> if_clause
%type<idsPtr> elsif_clause
%type<idsPtr> if_clauses

%defines 

/*
 NOTE: when receiving c strings from the lexer, the parser
 becomes responsible for deallocating them. Thus, they
 need to be deleted in every rule that they are used.
*/
%%

start: context_clause library_item{s_handler->addToRoot($2);}
       |library_item{s_handler->addToRoot($1);}

/* TODO: add error handling */
context_clause: with_clause
               |use_clause
               |context_clause with_clause
               |context_clause use_clause
with_clause: WITH library_names SEM
use_clause: USE library_names SEM

library_names: library_name {dealloc($1);}
              |library_names COMMA library_name {dealloc($3);}
library_name: IDENTIFIER {$$ = new QCString($1); delete $1;}
             |library_name DOT IDENTIFIER {
              QCString *name = $1;
              name->append(".");
              name->append($3);
              $$ = name;
              dealloc($3);}

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
                       dealloc($6);
                      }
                    | PACKAGE IDENTIFIER IS basic_decls
                      PRIVATE basic_decls END IDENTIFIER
                      {
                       $$ = s_handler->packageSpecBase($2, $4, $6);
                       dealloc( $8);
                      }

subprogram_decl:   subprogram_spec SEM {$$ = $1;}
subprogram_spec:   subprogram_spec_base|
                   doxy_comment subprogram_spec_base
                     {$$ = s_handler->subprogramSpec($2, $1);}
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
                     dealloc( $5);
                   }
                   |PACKAGE_BODY IDENTIFIER IS
                   decls END IDENTIFIER SEM
                   {
                     $$ = s_handler->packageBodyBase($2, $4); 
                     dealloc( $6);
                   }
                   |PACKAGE_BODY IDENTIFIER IS
                   decls BEGIN_ statements END SEM
                   {
                     $$ = s_handler->packageBodyBase($2, $4, $6); 
                   }
                   |PACKAGE_BODY IDENTIFIER IS
                   BEGIN_ statements END SEM
                   {
                     $$ = s_handler->packageBodyBase($2, NULL, $5); 
                   }
                   |PACKAGE_BODY IDENTIFIER IS
                   decls BEGIN_ statements END IDENTIFIER SEM
                   {
                     $$ = s_handler->packageBodyBase($2, $4, $6); 
                     dealloc( $8);
                   }
                   |PACKAGE_BODY IDENTIFIER IS
                   BEGIN_ statements END IDENTIFIER SEM
                   {
                     $$ = s_handler->packageBodyBase($2, NULL, $5); 
                     dealloc( $7);
                   }

subprogram_body:  subprogram_spec IS
                  BEGIN_ statements END tail
                  {
                    printf("PROG\n");
                    $$ = s_handler->subprogramBody($1, NULL, $4);
                  }
                  |subprogram_spec IS decls
                  BEGIN_ statements END tail
                  {
                    printf("PROG\n");
                    $$ = s_handler->subprogramBody($1, $3, $5);
                  }
tail:             SEM| IDENTIFIER SEM {dealloc( $1);}

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
                   |identifier_list COLON subtype ASS expression
                     {$$ = s_handler->paramSpec($1, $3, NULL, $5);}
                   |identifier_list COLON mode subtype ASS expression
                     {$$ = s_handler->paramSpec($1, $4, $3, $6);}

mode:              IN {$$ = new QCString("in");}
                   | OUT {$$ = new QCString("out");}
                   | IN OUT {$$ = new QCString("in out");}

decls:             body {$$ = s_handler->declsBase($1);}
                   |decl_item {$$ = s_handler->declsBase($1);}
                   |decl_items {$$ = s_handler->declsBase($1);}
                   |decls body {$$ = s_handler->decls($1, $2);}
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
                    type ASS expression SEM
                    {$$ = s_handler->objDeclBase($1, $3, $5);}
                    |identifier_list COLON type SEM
                    {$$ = s_handler->objDeclBase($1, $3);}

type:               subtype
                    {Expression *e = new Expression;
                     e->str = *$1;
                     e->ids.push_back(NEW_ID(*$1, @1));
                     $$ = e;
                     dealloc($1);}|array_type

array_type:         ARRAY LPAR array_subtype_definitions RPAR
                    OF subtype
                    {Expression *e = $3;
                     e->str.prepend("array (");
                     e->str.append(") of ");
                     e->str.append(*$6);
                     $$ = e;
                     dealloc($6);
                    }
                    |ARRAY LPAR array_subtype_definitions RPAR
                    OF ALIASED subtype
                    {Expression *e = $3;
                     e->str.prepend("array (");
                     e->str.append(") of aliased ");
                     e->str.append(*$7);
                     $$ = e;
                     dealloc($7);
                    }

array_subtype_definitions: array_subtype_definition
                          |array_subtype_definitions COMMA
                           array_subtype_definition
                        {Expression *e1 = $1;
                         Expression *e2 = $3;
                         e1->str.append(", ");
                         e1->str.append(e2->str);
                         moveExprIds(e1, e2);
                         $$ = e1;}
array_subtype_definition: subtype RANGE BOX
                        {Expression *e = new Expression;
                         e->ids.push_back(NEW_ID(*$1, @1));
                         e->str.append(*$1);
                         e->str.append(" range <>");
                         dealloc($1);
                         $$ = e;}
                        |range
                        |subtype
                        {Expression *e = new Expression;
                         e->ids.push_back(NEW_ID(*$1, @1));
                         e->str.append(*$1);
                         dealloc($1);
                         $$ = e;}
                         /*
discrete_subtype: range
                |subtype
                {Expression *e = new Expression;
                 e->ids.push_back(NEW_ID(*$1, @1));
                 e->str.append(*$1);
                 dealloc($1);
                 $$ = e;}

*/
range:                  range_attribute
                        |expression DDOT expression
                        {Expression *e1 = $1;
                         Expression *e2 = $3;
                         e1->str.append(" .. ");
                         e1->str.append(e2->str);
                         moveExprIds(e1, e2);
                         $$ = e1;}

range_attribute:        library_name TIC RANGE
                        {Expression *e = new Expression;
                         e->ids.push_back(NEW_ID(*$1, @1));
                         e->str.append(*$1);
                         e->str.append("'Range");
                         dealloc($1);
                         $$ = e;}
                        |library_name TIC RANGE LPAR expression RPAR
                        {Expression *e = $5;
                         e->ids.push_back(NEW_ID(*$1, @1));
                         e->str.prepend("'Range(");
                         e->str.prepend(*$1);
                         e->str.append(")");
                         dealloc($1);
                         $$ = e;}
                     
                      /* move to handlers */
identifier_list:    IDENTIFIER
                    {
                      Identifiers *ids = new Identifiers;
                      ids->push_front(NEW_ID($1, @1));

                      printf("identifier list\n");
                      $$ = ids;
                      dealloc($1);
                    }
                    |IDENTIFIER COMMA identifier_list
                    {
                      Identifiers *ids = $3;
                      ids->push_front(NEW_ID($1, @1));

                      $$ = ids;
                      dealloc($1);
                    }
                    
                    /* move to handlers */
subtype:            /*IDENTIFIER constraint
                    {
                      $$ = new QCString($1);
                      dealloc( $1);
                    }
                    |*/IDENTIFIER
                    {
                      $$ = new QCString($1);
                      dealloc( $1);
                    }

statements: statement
           |statement statements
           {Identifiers *s = $1;
            Identifiers *ss = $2;
            ss->splice(ss->begin(), *s);
            $$ = ss;
            dealloc( s);}

statement:  expression SEM {$$ = new Identifiers($1->ids);
                            dealloc($1);}
            | IDENTIFIER COLON expression SEM
                {$$ = new Identifiers($3->ids);
                dealloc($3);}
            |compound SEM
            |IDENTIFIER COLON compound SEM {$$ = $3;}

compound:   case_statement{$$=$1;}
            |loop_statement
            |if_statement{;}

if_statement: if_clause if_clauses END IF
              {$$ = moveIds($2, $1);}
            |IF if_clause END IF {$$ = $2;}
            |IF if_clause if_clauses ELSE statements END IF
            {moveIds($5,$3);
             $$=moveIds($5,$2);}
            |IF if_clause ELSE statements END IF
            {$$=moveIds($4, $2);}

if_clause: IF expression THEN statements
           {$$ = moveExprToIds($4, $2);}

elsif_clause:  ELSIF expression THEN statements
            {$$= moveExprToIds($4, $2);}

if_clauses: elsif_clause
            |if_clauses elsif_clause
            {$$= moveIds($1, $2);}

loop_statement: WHILE expression LOOP statements END LOOP
            {$$ = moveExprToIds($4, $2);}
              |FOR library_name IN range
               LOOP statements END LOOP 
              {
               $$ =moveExprToIds($6, $4);
              }
              |FOR library_name IN subtype
               LOOP statements END LOOP 
              {
                $6->push_back(NEW_ID(*$4, @5));
               $$ = $6;
               dealloc($4);
              }

case_statement: CASE expression IS cases END CASE
              {
               $$ =moveExprToIds($4, $2);
              }
case:        WHEN discrete_choice_list REF statements
              {
               $$ =moveExprToIds($4, $2);
              }
cases:       case
            |cases case
               {$$ = moveIds($1, $2);}

discrete_choice_list: discrete_choice
                      |discrete_choice_list discrete_choice
                      {
                       Expression *e1 = $1;
                       Expression *e2 = $2;
                       e1->str.append (" | ");
                       e1->str.append(e2->str);
                       moveExprIds(e1, e2);
                      }

discrete_choice: /*| expression*/
                        range
                        |subtype
                        {Expression *e = new Expression;
                         e->ids.push_back(NEW_ID(*$1, @1));
                         e->str.append(*$1);
                         dealloc($1);
                         $$ = e;}
               |OTHERS{$$ = new Expression("others");}
                

/* Note, this is an extremely permissive version of expression
   But enough  for doxygen's purposes. */
expression:primary
          |expression_sep primary {Expression *e = $2;
                                e->str.prepend(*$1);
                                dealloc($1);
                                $$ = e;}

           /*
          |expression  expression_sep primary
          {Expression *e1 = $1;
           Expression *e2 = $3;
           e1->str.append(*$2);
           e1->str.append(e1->str);
           moveExprIds(e1, e2);
           $$=e1;
           dealloc($2);}
          |expression  expression_sep expression_sep primary
          {Expression *e1 = $1;
           Expression *e2 = $4;
           e1->str.append(*$2);
           e1->str.append(*$3);
           e1->str.append(e1->str);
           moveExprIds(e1, e2);
           $$=e1;
           dealloc($2);
           dealloc($3);}
           */

primary:library_name {$$=new Expression(*$1, NEW_ID(*$1, @1));}
        |LPAR expression RPAR {
            Expression *e = $2;
            e->str.prepend("(");
            e->str.append(")");
            $$ = e;
        }
        |library_name LPAR RPAR
             {Expression *e = new Expression;
              Identifier call = NEW_ID(*$1, @1);
              call.str.append("()");
              e->ids.push_front(call);
              $$ = e;
              dealloc( $1);}
             |library_name LPAR call_params RPAR
             {Expression *e = $3;
              QCString call = *$1;
              call.append("(");
              call.append(e->str);
              call.append(")");
              e->str = call;
              e->ids.push_front(NEW_ID(call, @1));
              $$ = e;
              dealloc( $1);}
        |literal {$$=new Expression(*$1); dealloc($1);}

expression_sep: logical|operator|relational
              |ASS{$$=new QCString(" := ");}

/*
function_call: library_name LPAR RPAR
             {Expression *e = new Expression;
              Identifier call = NEW_ID(*$1, @1);
              call.str.append("()");
              e->ids.push_front(call);
              $$ = e;
              dealloc( $1);}
             |library_name LPAR call_params RPAR
             {Expression *e = $3;
              QCString call = *$1;
              call.append("(");
              call.append(e->str);
              call.append(")");
              e->str = call;
              e->ids.push_front(NEW_ID(call, @1));
              $$ = e;
              dealloc( $1);}
              */
call_params: param_assoc
           |param_assoc COMMA call_params
           {Expression *pa = $1;
            Expression *cp = $3;
            cp->str.append(" , ");
            cp->str.append($1->str);
            cp->ids.splice(cp->ids.begin(), pa->ids);
            $$ = cp;
            dealloc( pa);}
param_assoc: expression
            |library_name REF expression
            {Expression *e = $3;
             e->str.append(" => ");
             e->str.append(*$1);
             $$ = e;
             dealloc( $1);}

logical: AND {$$ =  new QCString(" AND ");}
       | OR {$$ =  new QCString(" OR ");}
       | XOR {$$ =  new QCString(" XOR ");}
literal: STRING_LITERAL|INTEGER|DECIMAL_LITERAL|BASED_LITERAL|
       Null{$$= new QCString(" Null ");}
relational: EQ{$$= new QCString(" = ");}
          | NEQ{$$= new QCString(" /= ");} 
          | LT{$$= new QCString(" < ");}
          | LTEQ {$$= new QCString(" <= ");}
          | GT{$$= new QCString(" > ");}
          | GTEQ{$$= new QCString(" >= ");}

operator: ADD {$$ =  new QCString(" + ");}
        | MINUS {$$ =  new QCString(" - ");}
        | AMB {$$ =  new QCString(" & ");}
        | MUL {$$ =  new QCString(" MUL ");}
        | DIV {$$ =  new QCString(" / ");}
        | MOD {$$ =  new QCString(" MOD ");}
        | REM {$$ =  new QCString(" REM ");}
        | EXP {$$ =  new QCString(" ** ");}
        | ABS {$$ =  new QCString(" ABS ");}
        | NOT {$$ =  new QCString(" NOT ");}
/* constraint: ;*/
                    
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
    bool should_save_comments = true;
    initAdaScanner(this, fileName, should_save_comments);
    setInputString(fileBuf);
    adaYYparse();
    msg("parse complete\n");
    const Entries& structComments = getStructDoxyComments();
    if (!structComments.empty())
    {
      Entries::const_iterator it = structComments.begin();
      for (;it!=structComments.end();++it)
      {
         root->addSubEntry(&(*it)->entry);
      }
      
      // Structural comments are not detroyed; the parser
      // is responsible for deallocating them.
      resetStructDoxyComments();
    }
    cleanupInputString();
    inputFile.close();
    eh.addFileSection(fileName);
  }
  msg("printing\n");
  eh.printRoot();
  msg("after print\n");
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
  s_sourceFile = fileDef;

  std::cout << "ADA CODE PARSER" << std::endl;
  bool should_save_comments = false;
  initAdaScanner(this, fileDef->name(), should_save_comments );
  CodeNode root;
  CodeHandler ch(&root);
  s_handler = &ch;
  setInputString(input);
  adaYYparse();
  cleanupInputString();

  s_handler->printRoot();
  std::cout << "ADDING CROSS REFS" << std::endl;
  addCrossRef(&root, "");

  /* Clean up static variables */
  //s_nodes_mem.clear();
  //s_symbols_mem.clear();
  //s_root = NULL;
}

void removeArgs(QCString &fun)
{
   int idx = fun.find('(');
   if (idx != -1)
      fun.truncate(idx);
}

void addCrossRef(CodeNode *root, QCString scope)
{
  NodeType type = root->type;
  QCString name = root->name;
  root->name_space = scope;

  MemberDef    *md;
  ClassDef     *cd;
  FileDef      *fd;
  NamespaceDef *nd;
  GroupDef     *gd;

  printf("ROOT %s, SCOPE%s\n", name.data(), scope.data());
  bool foundDef = getDefs(scope, name, "()", md,cd,fd,nd,gd,FALSE,s_sourceFile);
  
  /*
  if (root->type == ADA_PKG)
  {
    NamespaceDef *nd = getResolvedNamespace(
       QCString(scope + root->name).data());
    printf("package: %s.%s\n", scope.data(), root->name.data());
    if (nd)
    {
      printf("FOUND NAMESPACE");
      printf("nd %s\n", nd->name().data());
    }
  }
  */

  QCString newScope;
  if (root->type == ADA_PKG)
    newScope = scope + root->name + "::";
  else
    newScope = scope;
  printf("NEW SCOPE %s\n", newScope.data());

  if (foundDef)
  {
    printf("FOUND_DEF\n");
    MemberDef    *mdRef;
    ClassDef     *cdRef;
    FileDef      *fdRef;
    NamespaceDef *ndRef;
    GroupDef     *gdRef;

    /* add link to current node */

    IdentifiersIter rit = root->refs.begin();
    for (;rit != root->refs.end(); ++rit)
    {
      removeArgs(rit->str);
      printf("REF %s\n", rit->str.data()); 
      bool foundRefDef = getDefs(
            newScope, rit->str,"()",mdRef,cdRef,fdRef,ndRef,gdRef,
            FALSE,s_sourceFile);
      if (foundRefDef)
      {
        printf("FOUND REF DEF\n");
        if (md)
        {
          if (mdRef && mdRef->isLinkable())
          {
            printf("MD MD\n");
            addDocCrossReference(md, mdRef);
          }
          else if (cdRef && cdRef->isLinkable())
          {
            printf("MD cD\n");
            addDocCrossReference(md, mdRef);
          }
          else if (fdRef && fdRef->isLinkable())
          {
            printf("MD fD\n");
            addDocCrossReference(md, mdRef);

          }
        }
        else if (nd)
        {
          if (mdRef && mdRef->isLinkable())
          {
            printf("ND MD\n");
            addDocCrossReference(md, mdRef);
          }
          else if (cdRef && cdRef->isLinkable())
          {
            printf("ND CD\n");
            addDocCrossReference(md, mdRef);
          }
          else if (fdRef && fdRef->isLinkable())
          {
            printf("ND FD\n");
            addDocCrossReference(md, mdRef);
          }

        }
      }
      //CALL GRAPH + code link
      //root func ref func
      //root pac ref func

      //Code link
      // ref func
      // header
    }
  }


  /* recurse over all children */
  CodeNodesIter cit = root->children.begin();
  CodeNode *cn;


  for (;cit != root->children.end(); ++cit)
  {
    cn = *cit;
    if (cn->type == ADA_PKG || cn->type == ADA_SUBPROG)
    {
      addCrossRef(cn, newScope);
    }
  }
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
