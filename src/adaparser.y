/******************************************************************************
 *
 * 
 *
 * Copyright (C) 2016 Herman Lundkvist <herlu184@student.liu.se>
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

/* \file adaparser.y
* \brief the Ada parser used by doxygen.
*
* Used with bison to generate a parser.
*/

/* !!!!!!!!!!!!!!!!!!!!!! NOTE !!!!!!!!!!!!!!!!!!!!!!!!!!!
 when receiving c strings from the lexer, the parser
 becomes responsible for deallocating them. Thus, they
 need to be deleted in every rule that they are used.
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

/* from flex for bison to know about */
extern int adaYYlex();
extern int adaYYparse();
extern int adaYYwrap();
extern void adaYYrestart( FILE *new_file );
void adaYYerror (char const *s);

// the source file that is currently being parsed
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
%token True
%token False

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
%type<exprPtr> obj_decl_type
%type<exprPtr> subtype_indication
%type<exprPtr> array_type_definition
%type<paramsPtr> parameter_spec
%type<paramsPtr> parameter_specs
%type<paramsPtr> parameters
%type<qstrPtr> mode
%type<exprPtr> expression
%type<exprPtr> primary
%type<exprPtr> named_array_aggregate
%type<exprPtr> array_component_assocs
%type<exprPtr> array_component_assoc
%type<idsPtr> statement
%type<idsPtr> statements
%type<idsPtr> return_statement
%type<qstrPtr> expression_sep
%type<exprPtr> call_params
%type<exprPtr> param_assoc
%type<qstrPtr> logical
%type<qstrPtr> operator
%type<qstrPtr> relational
%type<qstrPtr>literal
%type<idsPtr> compound
%type<exprPtr> name
%type<qstrPtr> attribute_designator
%type<exprPtr> array_subtype_definitions
%type<exprPtr> array_subtype_definition
%type<exprPtr> range
%type<exprPtr> range_attribute
%type<exprPtr> discrete_subtype
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
%type<nodePtr> type_declaration
%type<nodesPtr> type_declarations
%type<nodePtr> type_definition
%type<nodesPtr> type_definitions
%type<nodePtr> full_type_declaration
%type<nodesPtr> full_type_declarations
%type<nodesPtr> enumeration_type_definition
%type<idsPtr>  enumeration_literals
%type<nodePtr> record_type_definition
%type<nodePtr> record_definition
%type<nodesPtr> component_list
%type<nodesPtr> component_item
%type<nodesPtr> component_declaration
%type<exprPtr> component_definition
%type<exprPtr> aggregate
%type<exprPtr> array_aggregate
%type<exprPtr> positional_array_aggregate
%type<exprPtr> expressions



%defines 

%%

start: context_clause library_item{s_handler->addToRoot($2);}
       |library_item{s_handler->addToRoot($1);}

/* TODO: add error handling */
context_clause: with_clause
               |use_clause
               |context_clause with_clause
               |context_clause use_clause
with_clause: WITH names SEM
use_clause: USE names SEM

direct_name: IDENTIFIER; /*TODO: OPERATOR SYMBOL*/
           /* TODO: imlement with namespaces*/

names: name {dealloc($1);}
              |names COMMA name {dealloc($3);}
name: IDENTIFIER {$$=new Expression($1, NEW_ID($1, @1));}
             /*selected_component/explicit_reference*/
             |name DOT IDENTIFIER
             {
              Expression *name = $1;
              name->str.append(".");
              name->str.append($3);
              name->ids.front().str = name->str;
              $$ = name;
              dealloc($3);
             }
             |name TIC attribute_designator 
             {
              Expression *name = $1;
              name->str.append("'");
              name->str.append(*$3);
              name->ids.front().str = name->str;
              $$ = name;
              dealloc($3);
             }
             /*qualified expression*/
             |name TIC aggregate 
             {
              $$ = exprPair($1, $3, "'");
             }
             /*function call and indexed component*/
             |name LPAR RPAR
             {Expression *e = $1;
              e->str.append("()");
              e->ids.front().str = e->str;
              $$ = e;
              dealloc( $1);}
             |name LPAR call_params RPAR
             {Expression *params = $3;
              Expression *prog = $1;
              prog->ids.front().str += "()";
              prog->str.append("(");
              prog->str.append(params->str);
              prog->str.append(")");
              $$ = moveExprIds(prog, params);
              }
              /*slice. NOTE: slices using subtype_indication currently interpreted as subprogram calls*/
            |name LPAR range RPAR
             {Expression *range = $3;
              Expression *name = $1;
              name->str.append("(");
              name->str.append(range->str);
              name->str.append(")");
              $$ = moveExprIds(name, range);
              }

              /* A simlpification, attributes with ( expression ) can be interpreted as a subprogram call*/
attribute_designator: IDENTIFIER {$$ = new QCString($1); dealloc($1);}

doxy_comment: SPECIAL_COMMENT

library_item: library_item_decl| library_item_body

library_item_decl: package_decl| subprogram_decl

library_item_body: package_body| subprogram_body


package_decl:      package_spec SEM{$$ = $1;}
package_spec:      package_spec_base
                   |doxy_comment package_spec_base
                     {$$ = s_handler->packageSpec($2, $1);}
package_spec_base: PACKAGE IDENTIFIER IS
                   basic_decls END IDENTIFIER
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
                   END tail
                   {
                     $$ = s_handler->packageBodyBase($2); 
                   }
                   |PACKAGE_BODY IDENTIFIER IS
                   decls END tail
                   {
                     $$ = s_handler->packageBodyBase($2, $4); 
                   }
                   |PACKAGE_BODY IDENTIFIER IS
                   decls BEGIN_ statements END tail
                   {
                     $$ = s_handler->packageBodyBase($2, $4, $6); 
                   }
                   |PACKAGE_BODY IDENTIFIER IS
                   BEGIN_ statements END tail
                   {
                     $$ = s_handler->packageBodyBase($2, NULL, $5); 
                   }

subprogram_body:  subprogram_spec IS
                  BEGIN_ statements END tail
                  {
                    $$ = s_handler->subprogramBody($1, NULL, $4);
                  }
                  |subprogram_spec IS decls
                  BEGIN_ statements END tail
                  {
                    $$ = s_handler->subprogramBody($1, $3, $5);
                  }
tail:             SEM| name SEM {dealloc( $1);} /* TODO change to name */

parameters:       parameter_spec
                  | parameter_specs parameter_spec
                   {$$ = s_handler->params($1, $2);}
parameter_specs:  parameter_spec SEM {$$ = $1;}
                  |parameter_specs parameter_spec SEM
                   {$$ = s_handler->params($1, $2);}
parameter_spec:    identifier_list COLON subtype_indication
                     {$$ = s_handler->paramSpec($1, $3);}
                   |identifier_list COLON mode subtype_indication
                     {$$ = s_handler->paramSpec($1, $4, $3);}
                   |identifier_list COLON subtype_indication ASS expression
                     {$$ = s_handler->paramSpec($1, $3, NULL, $5);}
                   |identifier_list COLON mode subtype_indication ASS expression
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

decl_items:         obj_decl| type_declarations;
decl_item:          subprogram_decl| package_decl| type_declaration;

type_declaration:   full_type_declaration|
                    doxy_comment full_type_declaration
                    {$$ = s_handler->addDoc($2, $1);}
                    /*aspect definition missing*/
type_declarations:  full_type_declarations|
                    doxy_comment full_type_declarations
                    {$$ = s_handler->addDocs($2, $1);}

full_type_declaration: TYPE IDENTIFIER IS type_definition SEM
                    {$$ = s_handler->full_type_declaration($2, $4);}
full_type_declarations: TYPE IDENTIFIER IS type_definitions SEM
                    {$$ = s_handler->full_type_declarations($2, $4);}
type_definition: array_type_definition
               {$$ = s_handler->type_definition($1);}
               | record_type_definition
                    /* access type, integer type, real type,
                    derived type, interface type*/
type_definitions: enumeration_type_definition

enumeration_type_definition: LPAR enumeration_literals RPAR
                    {$$ = s_handler->enumeration_type_definition($2);}
enumeration_literals: IDENTIFIER
                    {Identifiers* ids = new Identifiers;
                      ids->push_front(NEW_ID($1, @1));
                      $$ = ids;
                      dealloc($1);}
                     |IDENTIFIER COMMA enumeration_literals
                    {
                      Identifiers *ids = $3;
                      ids->push_front(NEW_ID($1, @1));

                      $$ = ids;
                      dealloc($1);
                    }
record_type_definition: record_definition
                      /*TODO: add abstract record support*/
                      |ABSTRACT record_definition
                      {$$ = $2;}
                      /*TODO: add tagged record support*/
                      |TAGGED record_definition
                      {$$ = $2;}
                      /*TODO: add limited record support*/
                      |LIMITED record_definition
                      {$$ = $2;}

record_definition:  RECORD component_list END RECORD
                    {$$ = s_handler->record_definition($2);}
                    |Null RECORD
                    {$$ = s_handler->record_definition();}
component_list:     component_item
                    /* TODO: find a way to implement variants in doxygen*/
                    |variant_part
                    {$$ = s_handler->component_list();}
                    |component_item component_list
                    {$$ = s_handler->component_list($1, $2);}
                    |Null SEM
                    {$$ = s_handler->component_list();}
component_item:     component_declaration /*TODO: aspect clasue*/
                    |doxy_comment component_declaration
                    {$$ = s_handler->addDocs($2, $1);}
component_declaration: identifier_list COLON component_definition SEM
                    {$$ = s_handler->component_declaration($1, $3);}
                     | identifier_list COLON component_definition
                     ASS expression SEM /*TODO: aspect spec*/
                    {$$ = s_handler->component_declaration($1, $3, $5);}
component_definition: subtype_indication
                    |ALIASED subtype_indication /*TODO: access definition*/
                    {
                     Expression *subtype = $2;
                     subtype->str.prepend("aliased ");
                     $$ = subtype;}

variant_part:       CASE direct_name IS variant_list END CASE SEM
variant_list:       variant|variant variant_list;
variant:            WHEN discrete_choice_list REF component_list

obj_decl:           obj_decl_base
                    |doxy_comment obj_decl_base
                    {$$ = s_handler->objDecl($2, $1);}
obj_decl_base:      identifier_list COLON 
                    obj_decl_type ASS expression SEM
                    {$$ = s_handler->objDeclBase($1, $3, $5);}
                    |identifier_list COLON obj_decl_type SEM
                    {$$ = s_handler->objDeclBase($1, $3);}

/*TODO: add access type*/
obj_decl_type:      subtype_indication
                    |array_type_definition

/*TODO: add access type*/
array_type_definition:  ARRAY LPAR array_subtype_definitions RPAR
                    OF subtype_indication
                    {Expression *e = $3;
                     Expression *type = $6;
                        printf("DDD\n");
                     e->str.prepend("array (");
                     e->str.append(") of ");
                     e->str.append(type->str);
                     moveExprIds(e, type);
                     $$ = e;
                    }
                    |ARRAY LPAR array_subtype_definitions RPAR
                    OF ALIASED subtype_indication
                    {Expression *e = $3;
                     Expression *type = $7;
                     e->str.prepend("array (");
                     e->str.append(") of aliased ");
                     e->str.append(type->str);
                     moveExprIds(e, type);
                     $$ = e;
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
array_subtype_definition:discrete_subtype
                        |subtype_indication RANGE BOX
                        {Expression *e = $1;
                         e->str.append(" range <>");
                         $$ = e;}
                         
discrete_subtype: range
                |subtype_indication

range:                  range_attribute
                        |expression DDOT expression
                        {Expression *e1 = $1;
                         Expression *e2 = $3;
                         e1->str.append(" .. ");
                         e1->str.append(e2->str);
                         moveExprIds(e1, e2);
                         $$ = e1;}

range_attribute:        name TIC RANGE
                        {Expression *e = $1;
                         e->str.append("'Range");
                         $$ = e;}
                        |name TIC RANGE LPAR expression RPAR
                        {Expression *name = $1;
                         Expression *expr = $5;  
                         name->str.append("'Range(");
                         name->str.append(expr->str);
                         name->str.append(")");
                         moveExprIds(name, expr);
                         $$ = name;}
                     
identifier_list:    IDENTIFIER
                    {
                      Identifiers *ids = new Identifiers;
                      ids->push_front(NEW_ID($1, @1));

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
                    
subtype_indication: name;

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
            |return_statement SEM
return_statement: RETURN expression {$$ = new Identifiers;}

compound:   case_statement{$$=$1;}
            |loop_statement
            |if_statement

if_statement:if_clause END IF
            |if_clause if_clauses END IF
            {$$ = moveIds($2, $1);}
            |if_clause if_clauses ELSE statements END IF
            {moveIds($4,$2);
             $$=moveIds($4,$1);}
            |if_clause ELSE statements END IF
            {$$=moveIds($3, $1);}

if_clause: IF expression THEN statements
           {$$ = moveExprToIds($4, $2);}

elsif_clause:  ELSIF expression THEN statements
            {$$= moveExprToIds($4, $2);}

if_clauses: elsif_clause
            |if_clauses elsif_clause
            {$$= moveIds($1, $2);}

loop_statement: WHILE expression LOOP statements loop_tail
            {$$ = moveExprToIds($4, $2);}
              |FOR name IN discrete_subtype
               LOOP statements loop_tail
              {
               moveExprToIds($6, $2);
               $$ =moveExprToIds($6, $4);
              }
              |FOR name IN REVERSE discrete_subtype
               LOOP statements loop_tail
              {
               moveExprToIds($7, $2);
               $$ =moveExprToIds($7, $5);
              }
loop_tail: END LOOP| END LOOP name {dealloc($3);}

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
                      |discrete_choice_list PIPE discrete_choice
                      {
                       Expression *e1 = $1;
                       Expression *e2 = $3;
                       e1->str.append (" | ");
                       e1->str.append(e2->str);
                       moveExprIds(e1, e2);
                       $$ = e1;
                      }

discrete_choice: expression
                |range
               |OTHERS{$$ = new Expression("others");}
                
/*
    TODO: imlpement proper expression
*/
expression: primary
          |primary expression_sep primary
primary:name
        |literal {$$=new Expression(*$1); dealloc($1);}
        |RANGE {$$=new Expression(" range ");}
        |LPAR expression RPAR {
            Expression *e = $2;
            e->str.prepend("(");
            e->str.append(")");
            $$ = e;
        }
        |aggregate

 /*NOTE: enumaration- and record aggregates are supported,
         but interpreted as named array aggregates,
         both are a subset of the latter.*/
aggregate: array_aggregate;

array_aggregate:positional_array_aggregate|named_array_aggregate;
/*NOTE: because of ambiguity when interpreting: arr:=(0),
        as ( expression ) or positinoal_array_aggregate?
        It is Always interpret it as the former */
positional_array_aggregate: LPAR expressions RPAR
            {$2->str.prepend("(");
             $2->str.append(")");
             $$ = $2;}
expressions: expression COMMA expression
           {
             $$ = exprPair($1, $3, ", ");
           }
           | expression COMMA expressions
           {
             $$ = exprPair($1, $3, ", ");
           }
named_array_aggregate: LPAR array_component_assocs RPAR
                     {$2->str.prepend("(");
                      $2->str.append(")");
                      $$ = $2;}
array_component_assocs: array_component_assoc
                      |array_component_assocs COMMA array_component_assoc
                     {
                       $$ = exprPair($1, $3, ", ");
                     }
array_component_assoc: discrete_choice_list REF expression
                     {
                       $$ = exprPair($1, $3, " =>");
                     }
                     | discrete_choice_list REF BOX
                     {
                       Expression *e = $1;
                       e->str.append (" => <>");
                       $$ = e;
                     }

expression_sep: logical|operator|relational
              |ASS{$$=new QCString(" := ");}

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
            |name REF expression
            {$$ = exprPair($1, $3, " => ");}

logical: AND {$$ =  new QCString(" AND ");}
       | OR {$$ =  new QCString(" OR ");}
       | XOR {$$ =  new QCString(" XOR ");}
literal: STRING_LITERAL|INTEGER|DECIMAL_LITERAL|BASED_LITERAL
       |True{$$= new QCString(" True ");}
       |False{$$= new QCString(" False ");}
       |Null{$$= new QCString(" Null ");}
relational: EQ{$$= new QCString(" = ");}
          | NEQ{$$= new QCString(" /= ");} 
          | LT{$$= new QCString(" < ");}
          | LTEQ {$$= new QCString(" <= ");}
          | GT{$$= new QCString(" > ");}
          | GTEQ{$$= new QCString(" >= ");}

operator: ADD {$$ =  new QCString(" + ");}
        | MINUS {$$ =  new QCString(" - ");}
        | AMB {$$ =  new QCString(" & ");}
        | MUL {$$ =  new QCString(" * ");}
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
    const Entries& structComments = getStructDoxyComments();
    if (!structComments.empty())
    {
      Entries::const_iterator it = structComments.begin();
      for (;it!=structComments.end();++it)
      {
         root->addSubEntry(&(*it)->entry);
      }
      
    }
    inputFile.close();
    eh.addFileSection(fileName);
    adaScannerCleanup();
  }
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

  bool should_save_comments = false;
  initAdaScanner(this, fileDef->name(), should_save_comments );
  CodeNode root;
  CodeHandler ch(&root);
  s_handler = &ch;
  setInputString(input);
  adaYYparse();

  addCrossRef(&root, "");

  adaScannerCleanup();

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

  bool foundDef = getDefs(scope, name, "()", md,cd,fd,nd,gd,FALSE,s_sourceFile);
  
  QCString newScope;
  if (root->type == ADA_PKG)
    newScope = scope + root->name + "::";
  else
    newScope = scope;

  if (foundDef)
  {
    MemberDef    *mdRef;
    ClassDef     *cdRef;
    FileDef      *fdRef;
    NamespaceDef *ndRef;
    GroupDef     *gdRef;

    /* add links from the current node  to all
       references that are found */
    IdentifiersIter rit = root->refs.begin();
    for (;rit != root->refs.end(); ++rit)
    {
      removeArgs(rit->str);
      bool foundRefDef = getDefs(
            newScope, rit->str,"()",mdRef,cdRef,fdRef,ndRef,gdRef,
            FALSE,s_sourceFile);
      if (foundRefDef)
      {
        if (md)
        {
          if (mdRef && mdRef->isLinkable())
          {
            addDocCrossReference(md, mdRef);
          }
          else if (cdRef && cdRef->isLinkable())
          {
            addDocCrossReference(md, mdRef);
          }
          else if (fdRef && fdRef->isLinkable())
          {
            addDocCrossReference(md, mdRef);

          }
        }
        else if (nd)
        {
          if (mdRef && mdRef->isLinkable())
          {
            addDocCrossReference(md, mdRef);
          }
          else if (cdRef && cdRef->isLinkable())
          {
            addDocCrossReference(md, mdRef);
          }
          else if (fdRef && fdRef->isLinkable())
          {
            addDocCrossReference(md, mdRef);
          }

        }
      }
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
