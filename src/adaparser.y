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
%token LINE
%token NEWLINE
%token TIC
%token DDOT
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
%type<paramsPtr> parameter_spec
%type<paramsPtr> parameter_specs
%type<paramsPtr> parameters
%type<qstrPtr> mode
%type<exprPtr> expression
%type<qstrPtr> expression_part
%type<idsPtr> statement
%type<idsPtr> statement_part
%type<idsPtr> statement_parts
%type<idsPtr> statements
%type<exprPtr> function_call
%type<exprPtr> call_params
%type<exprPtr> param_assoc
%type<qstrPtr> logical
%type<qstrPtr> operator
%type<idsPtr> compound

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
                     delete $8;
                   }
                   |PACKAGE_BODY IDENTIFIER IS
                   BEGIN_ statements END IDENTIFIER SEM
                   {
                     $$ = s_handler->packageBodyBase($2, NULL, $5); 
                     delete $7;
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
                    subtype ASS expression SEM
                    {$$ = s_handler->objDeclBase($1, $3, $5);}
                    |identifier_list COLON subtype SEM
                    {$$ = s_handler->objDeclBase($1, $3);}
                     
                      /* move to handlers */
identifier_list:    IDENTIFIER
                    {
                      Identifiers *ids = new Identifiers;
                      ids->push_front(NEW_ID($1, @1));

                      printf("identifier list\n");
                      $$ = ids;
                      delete $1;
                    }
                    |IDENTIFIER COMMA identifier_list
                    {
                      Identifiers *ids = $3;
                      ids->push_front(NEW_ID($1, @1));

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

statements: statement
           |statement statements
           {Identifiers *s = $1;
            Identifiers *ss = $2;
            ss->splice(ss->begin(), *s);
            $$ = ss;
            delete s;}

statement:  statement_parts SEM {$$ = $1;}
      
statement_parts: statement_part
                |expression
                {Identifiers *ids = new Identifiers;
                 ids->splice(ids->begin(), $1->ids);
                 $$ = ids;
                 delete $1;}

                |statement_part statement_parts
                 {Identifiers *s = $1;
                  Identifiers *ss = $2;
                  ss->splice(ss->begin(), *s);
                  $$ = ss;
                  delete s;}
                |expression statement_part statement_parts
                {Identifiers *ss = $3;
                 Identifiers *s = $2;
                 Expression *e = $1;
                 ss->splice(ss->begin(), *s);
                 ss->splice(ss->begin(), e->ids);
                 delete s;
                 delete e;
                 $$ = ss;}


statement_part: relational {$$ = new Identifiers;}
                |compound_part {$$ = new Identifiers;}
                |ASS {$$ = new Identifiers;}
                |compound

compound: IF statements END IF {$$ = $2;}
          |WHILE statements END LOOP {$$ = $2;}
          |FOR statements END LOOP {$$ = $2;}
          |CASE statements END CASE {$$ = $2;}

/* Note, this is an extremely permissive version of expression
   But enough  for doxygen's purposes. */
expression: expression_part
        {Expression *e = new Expression;
         e->str = *$1;
         delete $1;
         $$ = e;}
       |IDENTIFIER {Expression *e = new Expression;
                    e->str = $1;
                    e->ids.push_front(NEW_ID($1, @1));
                    delete $1;
                    $$ = e;}
       |function_call
       | expression expression_part{Expression *e = $1;
                    e->str.append(" ");
                    e->str.append(*$2);
                    delete $2;
                    $$ = e;}
       | expression function_call
        {
         Expression *e = $1;
         Expression *f = $2;
         e->str.append(" ");
         e->str.append(f->str);
         e->ids.splice(e->ids.begin(), f->ids);
         delete f;
         $$ = e;
        }
       |expression IDENTIFIER {Expression *e = $1;
                    e->str.append(" ");
                    e->str.append($2);
                    e->ids.push_front(NEW_ID($2, @2));
                    delete $2;
                    $$ = e;}

function_call: IDENTIFIER LPAR RPAR
             {Expression *e = new Expression;
              Identifier call = NEW_ID($1, @1);
              call.str.append("()");
              e->ids.push_front(call);
              $$ = e;
              delete $1;}
             |IDENTIFIER LPAR call_params RPAR
             {Expression *e = $3;
              QCString call = $1;
              call.append("(");
              call.append(e->str);
              call.append(")");
              e->str = call;
              e->ids.push_front(NEW_ID(call, @1));
              $$ = e;
              delete $1;}
call_params: param_assoc
           |param_assoc COMMA call_params
           {Expression *pa = $1;
            Expression *cp = $3;
            cp->str.append(" , ");
            cp->str.append($1->str);
            cp->ids.splice(cp->ids.begin(), pa->ids);
            $$ = cp;
            delete pa;
           }
param_assoc: expression
            |IDENTIFIER REF expression
            {Expression *e = $3;
             e->str.append(" => ");
             e->str.append($1);
             $$ = e;
             delete $1;}

expression_part: logical| operator
      |Null {$$ =  new QCString("NULL");}
      |TIC {$$ =  new QCString("'");}
logical: AND {$$ =  new QCString("AND");}
       | OR {$$ =  new QCString("OR");}
       | XOR {$$ =  new QCString("XOR");}
relational: EQ  | NEQ  | LT  | LTEQ  | GT  | GTEQ
operator: ADD {$$ =  new QCString("+");}
        | MINUS {$$ =  new QCString("-");}
        | AMB {$$ =  new QCString("&");}
        | MUL {$$ =  new QCString("MUL");}
        | DIV {$$ =  new QCString("/");}
        | MOD {$$ =  new QCString("MOD");}
        | REM {$$ =  new QCString("REM");}
        | EXP {$$ =  new QCString("**");}
        | ABS {$$ =  new QCString("ABS");}
        | NOT {$$ =  new QCString("NOT");}
compound_part: THEN| ELSIF| ELSE| WHEN| OTHERS| LOOP| IN| REVERSE
constraint:;
                    
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

bool canAddRef(NodeType type,
                  MemberDef    *md,
                  ClassDef     *cd,
                  FileDef      *fd,
                  NamespaceDef *nd,
                  GroupDef     *gd)
{
  return ((type == ADA_SUBPROG && md)||
          (type == ADA_PKG && nd));

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

  printf("ROOT %s, SCOPE%s\n", root->name.data(), scope.data());
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

  if (foundDef && canAddRef(type, md, cd, fd, nd, gd))
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
      printf("REF %s\n", rit->str.data()); 
      bool foundRefDef = getDefs(
            newScope, rit->str,"()",md,cd,fd,nd,gd,
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
