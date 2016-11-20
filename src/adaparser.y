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
%token PROTECTED_ // ADA 95
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
/*this is defined as a QCString because it can be several bytes in non ascii*/
%token <qstrPtr>CHAR_LITERAL

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
%type<qstrPtr> obj_mod
%type<nodePtr> decl_item
%type<nodesPtr> decl_items
%type<idsPtr> identifier_list
%type<nodePtr> library_item
%type<nodePtr> library_item_decl
%type<nodePtr> library_item_body
%type<exprPtr> obj_decl_type
%type<exprPtr> subtype_indication
/*%type<exprPtr> subtype_mark*/
%type<exprPtr> array_type_definition
%type<paramsPtr> parameter_spec
%type<paramsPtr> parameter_specs
%type<paramsPtr> parameters
%type<qstrPtr> mode
%type<exprPtr> named_array_aggregate
%type<exprPtr> array_component_assocs
%type<exprPtr> array_component_assoc
%type<idsPtr> statement
%type<idsPtr> statements
%type<idsPtr> return_statement
%type<idsPtr> block_statement
%type<exprPtr> call_params
%type<exprPtr> param_assoc
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


%type<nodePtr> renaming_declaration
%type<nodePtr> object_renaming_declaration
%type<nodePtr> exception_renaming_declaration
%type<nodePtr> package_renaming_declaration
%type<nodePtr> subprogram_renaming_declaration
%type<nodePtr> generic_renaming_declaration

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
%type<qstrPtr> access_prefix
%type<qstrPtr> general_access_mod
%type<paramsPtr> parameter_and_result_profile
%type<paramsPtr> parameter_profile
%type<qstrPtr> defining_designator
%type<exprPtr> access_definition
%type<nodePtr> access_type_definition
%type<nodePtr> access_to_object_definition
%type<nodePtr> access_to_subprogram_definition

%type<qstrPtr> unary_op
%type<qstrPtr> adding_op
%type<qstrPtr> relation_op
%type<qstrPtr> relational_op
%type<qstrPtr> multiplying_op

%type<exprPtr> expression
%type<exprPtr> remaining_expression
%type<exprPtr> qualified_expression
%type<exprPtr> membership_test
%type<exprPtr> membership_choice_list
%type<exprPtr> membership_choice
%type<exprPtr> choice_expression
%type<exprPtr> choice_relation
%type<exprPtr> unary
%type<exprPtr> simple_expression
%type<exprPtr> term
%type<exprPtr> factor
%type<exprPtr> allocator
%type<exprPtr> primary


%defines 

%%

start: context_clause library_item{s_handler->addToRoot($2);}
       |library_item{s_handler->addToRoot($1);}

/* TODO: add error handling */
context_clause: with_clause
               |use_clause
               |context_clause with_clause
               |context_clause use_clause
/* TODO: handle WITH and USE in doxygen, will be similar to using in c++
         right now this causes memory leak with names.*/
with_clause: WITH names SEM
             |WITH PRIVATE names SEM
             |LIMITED WITH names SEM
             |LIMITED WITH PRIVATE names SEM

use_clause: USE names SEM
            |USE TYPE names SEM
            |USE TYPE ALL names SEM

null_exclusion: NOT Null;

access_prefix: ACCESS
             {$$ = new QCString("access ");}
             |null_exclusion ACCESS
             {$$ = new QCString("Not null access ");}
             |ACCESS CONSTANT
             {$$ = new QCString("access constant ");}
             |ACCESS PROTECTED_
             {$$ = new QCString("access protected ");}
             |null_exclusion ACCESS PROTECTED_
             {$$ = new QCString("not null access protected");}
access_definition:access_prefix subtype_indication
                 {Expression *e = $2;
                  e->str.prepend(*$1);
                  dealloc($1);
                  $$ = e;}
                 |access_prefix parameter_profile
                 {Parameters *p = $2;
                  Expression *e = new Expression(*$1);
                  e->str.append(adaArgListToString(*(p->args)));
                  e->ids.splice(e->ids.begin(), p->refs);
                  dealloc($1);
                  dealloc(p);
                  $$ = e;}
                 |access_prefix parameter_and_result_profile
                 {Parameters *p = $2;
                  Expression *e = new Expression(*$1);
                  e->str.append(adaArgListToString(*(p->args)));
                  e->ids.splice(e->ids.begin(), p->refs);
                  dealloc($1);
                  dealloc(p);
                  $$ = e;}
access_type_definition:
                      access_to_object_definition
                      |access_to_subprogram_definition
                      |null_exclusion access_to_object_definition
                      {$$=$2;}
                      |null_exclusion access_to_subprogram_definition
                      {$$=$2;}
general_access_mod:
                  ALL {$$ = new QCString("all ");}
                  |CONSTANT {$$ = new QCString("constant ");}

access_to_object_definition:
            ACCESS subtype_indication
            {$$ = s_handler->accessToObjectDefinition($2);}
            |ACCESS general_access_mod subtype_indication
            {$$ = s_handler->accessToObjectDefinition($3, $2);}

access_to_subprogram_definition:
                ACCESS PROCEDURE parameter_profile
                {$$ = s_handler->accessToProcedureDefinition($3);}
                |ACCESS FUNCTION parameter_and_result_profile
                {$$ = s_handler->accessToFunctionDefinition($3);}
                |ACCESS PROTECTED_ PROCEDURE parameter_profile
                {$$ = s_handler->accessToProcedureDefinition($4, true);}
                |ACCESS PROTECTED_ FUNCTION parameter_and_result_profile
                {$$ = s_handler->accessToFunctionDefinition($4, true);}


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
             |qualified_expression
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
attribute_designator: 
                IDENTIFIER
                {$$ = new QCString($1); dealloc($1);}
                /*|IDENTIFIER LPAR expression RPAR
                {$$ = new QCString($1); dealloc($1); dealloc($3);}*/
                |DELTA
                {$$ = new QCString(" Delta ");}
                |ACCESS
                {$$ = new QCString(" Access ");}
                |DIGITS
                {$$ = new QCString(" Digits ");}
                |MOD
                {$$ = new QCString(" Mod ");}

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
defining_designator: IDENTIFIER
                   {$$ = new QCString($1); dealloc($1);}
                   |defining_designator DOT IDENTIFIER
                   {QCString *str = $1;
                   str->append(".");
                   str->append($3);
                   dealloc($3);
                   $$ = str;
                   }
subprogram_spec_base:  PROCEDURE defining_designator
                   {
                     $$ = s_handler->subprogramSpecBase($2);
                   }
                   |PROCEDURE defining_designator parameter_profile
                   {
                     $$ = s_handler->subprogramSpecBase($2, $3);
                   }
                   |FUNCTION defining_designator parameter_and_result_profile
                   {
                     $$ = s_handler->subprogramSpecBase($2, $3);
                   }

parameter_profile: LPAR parameters RPAR {$$ = $2;}
parameter_and_result_profile:
                   RETURN access_definition
                   {Parameters *p = new Parameters;
                    p->type = $2;
                    $$ = p;}
                   |RETURN subtype_indication
                   {Parameters *p = new Parameters;
                    p->type = $2;
                    $$ = p;}
                   | RETURN null_exclusion
                        subtype_indication
                   {Parameters *p = new Parameters;
                    p->type = $3;
                    $$ = p;}
                   |LPAR parameters RPAR RETURN access_definition
                   {Parameters *p = $2;
                    p->type = $5;
                    $$ = p;}
                   | LPAR parameters RPAR RETURN subtype_indication
                   {Parameters *p = $2;
                    p->type = $5;
                    $$ = p;}
                   | LPAR parameters RPAR RETURN null_exclusion
                        subtype_indication
                   {Parameters *p = $2;
                    p->type = $6;
                    $$ = p;}

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
tail:             SEM| name SEM {dealloc( $1);}

parameters:       parameter_specs
parameter_specs:  parameter_spec {$$ = $1;}
                  |parameter_specs SEM parameter_spec
                   {$$ = s_handler->params($1, $3);}
parameter_spec:    identifier_list COLON subtype_indication
                     {$$ = s_handler->paramSpec($1, $3);}
                   |identifier_list COLON mode subtype_indication
                     {$$ = s_handler->paramSpec($1, $4, $3);}
                   |identifier_list COLON subtype_indication ASS expression
                     {$$ = s_handler->paramSpec($1, $3, NULL, $5);}
                   |identifier_list COLON mode subtype_indication ASS expression
                     {$$ = s_handler->paramSpec($1, $4, $3, $6);}
                   |identifier_list COLON access_definition
                     {$$ = s_handler->paramSpec($1, $3);}
                   |identifier_list COLON access_definition ASS expression
                     {$$ = s_handler->paramSpec($1, $3, NULL, $5);}

mode:              IN {$$ = new QCString("in");}
                   | OUT {$$ = new QCString("out");}
                   | IN OUT {$$ = new QCString("in out");}

/*TODO handle use_clause, add aspect_clause*/
decls:             body {$$ = s_handler->declsBase($1);}
                   |decl_item {$$ = s_handler->declsBase($1);}
                   |decl_items {$$ = s_handler->declsBase($1);}
                   |use_clause {$$ = NULL;}
                   |decls body {$$ = s_handler->decls($1, $2);}
                   |decls decl_item {$$ = s_handler->decls($1, $2);}
                   |decls decl_items {$$ = s_handler->decls($1, $2);}
                   |decls use_clause {$$ = $1;}

basic_decls:        decl_items {$$ = s_handler->declsBase($1);}
                    |decl_item {$$ = s_handler->declsBase($1);}
                    |basic_decls decl_items
                    {$$ = s_handler->decls($1, $2);}
                    |basic_decls decl_item
                    {$$ = s_handler->decls($1, $2);}

decl_items:         obj_decl| type_declarations;
decl_item:          subprogram_decl| package_decl| type_declaration
                    |renaming_declaration;

overriding_indicator: OVERRIDING
                    NOT OVERRIDING
/* TODO: add aspect_declaration
         figure out how to represent renames in doxygen
         
         dealloc*/
renaming_declaration:object_renaming_declaration
                    |exception_renaming_declaration
                    |package_renaming_declaration
                    |subprogram_renaming_declaration
                    |generic_renaming_declaration
object_renaming_declaration:
                    IDENTIFIER COLON name RENAMES name SEM
                    {$$ = NULL;}
                    |IDENTIFIER COLON null_exclusion name RENAMES name SEM
                    {$$ = NULL;}
                    |IDENTIFIER COLON access_definition RENAMES name SEM
                    {$$ = NULL;}
exception_renaming_declaration:
                    IDENTIFIER EXCEPTION RENAMES name SEM
                    {$$ = NULL;}
package_renaming_declaration:
                    PACKAGE name RENAMES name SEM
                    {$$ = NULL;}
subprogram_renaming_declaration:
                    subprogram_spec RENAMES name SEM
                    {$$ = NULL;}
                    |overriding_indicator subprogram_spec RENAMES name SEM
                    {$$ = NULL;}
generic_renaming_declaration:
                    GENERIC PACKAGE name RENAMES name SEM
                    {$$ = NULL;}
                    |GENERIC PROCEDURE name RENAMES name SEM
                    {$$ = NULL;}
                    |GENERIC FUNCTION name RENAMES name SEM
                    {$$ = NULL;}

type_declaration:   full_type_declaration|
                    doxy_comment full_type_declaration
                    {$$ = s_handler->addDoc($2, $1);}
                    /*aspect definition missing*/
type_declarations:  full_type_declarations|
                    doxy_comment full_type_declarations
                    {$$ = s_handler->addDocs($2, $1);}

/*TODO add discriminant part*/
full_type_declaration: TYPE IDENTIFIER IS type_definition SEM
                    {$$ = s_handler->full_type_declaration($2, $4);}
full_type_declarations: TYPE IDENTIFIER IS type_definitions SEM
                    {$$ = s_handler->full_type_declarations($2, $4);}
type_definition: array_type_definition
               {$$ = s_handler->type_definition($1);}
               | record_type_definition
               | access_type_definition
                    /* integer type, real type,
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
                     |access_definition
                     |ALIASED access_definition
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
                    /* NOTE: grammar for obj_decls_base written
                             this way to prevent s/r conflicts with
                             object_renaming_declaration. */

obj_mod:    
            CONSTANT
            {$$ = new QCString(" constant ");}
            |ALIASED
            {$$ = new QCString(" aliased ");}
            |CONSTANT ALIASED
            {$$ = new QCString(" constant ");}

obj_decl_base:      
                    IDENTIFIER COLON
                    obj_decl_type ASS expression SEM
                    {$$ = s_handler->objDeclBase($1, $3, $5);}
                    |IDENTIFIER COLON obj_decl_type SEM
                    {$$ = s_handler->objDeclBase($1, $3);}
                    |IDENTIFIER COMMA   identifier_list COLON
                    obj_decl_type ASS expression SEM
                    {$$ = s_handler->objDeclBase($1, $3, $5, $7);}
                    |IDENTIFIER COMMA identifier_list COLON
                     obj_decl_type SEM
                    {$$ = s_handler->objDeclBase($1, $3, $5);}

                    |IDENTIFIER COLON obj_mod 
                    obj_decl_type ASS expression SEM
                    {$$ = s_handler->objDeclBase($1, $4, $6, $3);}
                    |IDENTIFIER COLON  obj_mod obj_decl_type SEM
                    {$$ = s_handler->objDeclBase($1, $4, NULL, $3);}
                    |IDENTIFIER COMMA   identifier_list COLON obj_mod
                    obj_decl_type ASS expression SEM
                    {$$ = s_handler->objDeclBase($1, $3, $6, $8, $5);}
                    |IDENTIFIER COMMA identifier_list COLON
                     obj_mod obj_decl_type SEM
                    {$$ = s_handler->objDeclBase($1, $3, $6, NULL, $5);}

obj_decl_type:      subtype_indication
                    |array_type_definition
                    |access_definition

array_type_definition:  ARRAY LPAR array_subtype_definitions RPAR
                    OF subtype_indication
                    {Expression *e = $3;
                     Expression *type = $6;
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
                        |simple_expression DDOT simple_expression
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
/*subtype_mark: name;*/

statements: statement
           |statements statement
           {Identifiers *s = $1;
            Identifiers *ss = $2;
            ss->splice(ss->begin(), *s);
            $$ = ss;
            dealloc( s);}

statement:  
            /* Procedure_call, code_statement,
               null_statement */
            expression SEM {$$ = new Identifiers($1->ids);
                            dealloc($1);}
            /* assignment statement */
            | name ASS expression SEM
                {$$ = new Identifiers($3->ids);
                dealloc($3);}
            /* compound_statement */
            |compound
            |IDENTIFIER COLON compound {$$ = $3;}
            /* simple and extended return statement */
            |return_statement SEM
            /* abort_statement*/
            | ABORT name SEM
                {$$ = new Identifiers($2->ids);
                dealloc($2);}
            /* goto_statement */
            | GOTO name SEM
                {$$ = new Identifiers($2->ids);
                dealloc($2);}
            /* exit_statement */
            | EXIT SEM
            {$$ = new Identifiers;}
            | EXIT expression SEM
            {$$ = new Identifiers($2->ids);
                dealloc($2);}

            | EXIT name WHEN expression SEM
           {Identifiers *s = new Identifiers($2->ids);
            Identifiers *ss = new Identifiers($4->ids);
            ss->splice(ss->begin(), *s);
            $$ = ss;
            dealloc( s);
            dealloc($2);
            dealloc($4);}

            /* raise_statement */
            |RAISE SEM
            {$$ = new Identifiers;}
            |RAISE name SEM
                {$$ = new Identifiers($2->ids);
                dealloc($2);}
            |RAISE name WITH expression SEM
           {Identifiers *s = new Identifiers($2->ids);
            Identifiers *ss = new Identifiers($4->ids);
            ss->splice(ss->begin(), *s);
            $$ = ss;
            dealloc( s);
            dealloc($2);
            dealloc($4);}
            /* TODO delay statement, entry_call_statement,
            reque_statement*/

/*simple return and extended return*/
return_statement: RETURN {$$ = new Identifiers;}
                |RETURN expression
                {$$ = new Identifiers($2->ids);
                dealloc($2);}
                |RETURN subtype_indication DO statements END RETURN
           {Identifiers *s = new Identifiers($2->ids);
            Identifiers *ss = $4;
            ss->splice(ss->begin(), *s);
            $$ = ss;
            dealloc( s);
            dealloc($2);}

compound:   case_statement SEM{$$=$1;}
            |loop_statement SEM
            |if_statement SEM
            |block_statement

block_statement:
               /* TODO: 2016-11-14 the references used in decls should
               be returned somehow*/
            DECLARE decls BEGIN_ statements END tail
            {$$ = $4;}
            |BEGIN_ statements END tail
            {$$ = $2;}
            |DECLARE BEGIN_ statements END tail
            {$$ = $3;}

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

discrete_choice: choice_expression
                |range
               |OTHERS{$$ = new Expression("others");}
                
qualified_expression:
            name TIC aggregate 
             {
              $$ = exprPair($1, $3, "'");
             }

/* NOTE: The syntax is formulated a bit different from the reference, but it
        describes the same language. The reason for this rewrite is
        because of conflicts between "positional_array_aggregate", 
        '(' expression ')' and "named_array_aggregate".*/
expression: 

          choice_expression
          |membership_test
          |membership_test relation_op remaining_expression
          {
            $$ = exprPair($1, $3, *$2);
            $$ = $1;
            dealloc($2);
          }
          |choice_expression relation_op membership_test relation_op remaining_expression
          {
            Expression *e1 = exprPair($1, $3, *$2);
            exprPair(e1, $5);
            $$ = $1;
            dealloc($2);
            dealloc($4);
          }
remaining_expression:
          choice_relation
          |membership_test
          |remaining_expression relation_op choice_relation
          {
            $$ = exprPair($1, $3, *$2);
            $$ = $1;
            dealloc($2);
          }
          |remaining_expression relation_op membership_test
          {
            $$ = exprPair($1, $3, *$2);
            $$ = $1;
            dealloc($2);
          }

membership_test:
        simple_expression IN membership_choice_list
          {
            $$ = exprPair($1, $3, " IN ");
          }
        |simple_expression NOT IN membership_choice_list
          {
            $$ = exprPair($1, $4, " NOT IN ");
          }

membership_choice_list:
        membership_choice
        |membership_choice_list PIPE membership_choice
          {
            $$ = exprPair($1, $3, " | ");
          }
membership_choice:
        /* NOTE: subtype_mark is included in "simple_expression" */
        simple_expression /*NOTE: changed from choice_expression
                                to simple_expression according to
                                AI12-0039-1*/
        |range
choice_expression: 
          choice_relation
          |choice_expression relation_op choice_relation
          {
            $$ = exprPair($1, $3, *$2);
            $$ = $1;
            dealloc($2);
          }
choice_relation:
        simple_expression
        |simple_expression relational_op simple_expression
          {
            $$ = exprPair($1, $3, *$2);
            $$ = $1;
            dealloc($2);
          }
simple_expression:
                 unary
                 |simple_expression adding_op unary
          {
            $$ = exprPair($1, $3, *$2);
            $$ = $1;
            dealloc($2);
          }

unary:
      term
     |unary_op term
     {
        Expression *e = $2;
        e->str.prepend(*$1);
        $$ = e;
        dealloc($1);
     }

term: factor
    |term multiplying_op factor;

factor: primary
      |primary EXP primary
     {
        $$ = exprPair($1, $3, " ** ");
    }
      |ABS primary
     {
        Expression *e = $2;
        e->str.prepend(" ABS ");
        $$ = e;
     }
      |NOT primary
     {
        Expression *e = $2;
        e->str.prepend(" NOT ");
        $$ = e;
     }

primary:name
        |literal {$$=new Expression(*$1); dealloc($1);}
        |LPAR expression RPAR {
            Expression *e = $2;
            e->str.prepend("(");
            e->str.append(")");
            $$ = e;
        }
        |aggregate
        |allocator;
        /* NOTE: "conditional_expression" and "quantified_expression"
                 (ada 2012) not currently supported*/

        /* NOTE: in the reference syntax "subtype_indication" and
                "qualified_expression"
                 is used in this rule. However since we do not differentiate
                 between different types of names, we use "name" which
                 is a superset of the two first.*/

allocator:NEW name
     {
        Expression *e = $2;
        e->str.prepend(" NEW ");
        $$ = e;
     }


 /*NOTE: enumaration- and record aggregates are supported,
         but interpreted as named array aggregates,
         both are a subset of the latter.*/
aggregate: array_aggregate;

/* NOTE: Reduce/reduce conflicts occur in array_aggregates due to
using one token lookahead although the grammar is unambiguos. This
solved by using GLR parsing, we expect 6 rr conflicts from this
(cannot decide wether to reduce relation for positional_aggregate,
or redure choice_relation for named_array_aggregate. */
array_aggregate:positional_array_aggregate|named_array_aggregate;
positional_array_aggregate: LPAR expressions RPAR
            {$2->str.prepend("(");
             $2->str.append(")");
             $$ = $2;}
expressions: expression COMMA expression
           {
             $$ = exprPair($1, $3, ", ");
           }
           | expressions COMMA expression
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

literal:
       STRING_LITERAL|INTEGER|DECIMAL_LITERAL|BASED_LITERAL
       |CHAR_LITERAL
       |True{$$= new QCString(" True ");}
       |False{$$= new QCString(" False ");}
       |Null{$$= new QCString(" Null ");}

adding_op:
         ADD {$$ =  new QCString(" + ");}
        | MINUS {$$ =  new QCString(" - ");}
        | AMB {$$ =  new QCString(" & ");}

unary_op:
        ADD {$$ =  new QCString(" + ");}
        | MINUS {$$ =  new QCString(" - ");}

relation_op:
        AND {$$ =  new QCString(" AND ");}
       | OR {$$ =  new QCString(" OR ");}
       | AND THEN {$$ =  new QCString(" AND THEN");}
       | OR ELSE {$$ =  new QCString(" OR ELSE");}
       | XOR {$$ =  new QCString(" XOR ");}
relational_op:
            EQ{$$= new QCString(" = ");}
          | NEQ{$$= new QCString(" /= ");} 
          | LT{$$= new QCString(" < ");}
          | LTEQ {$$= new QCString(" <= ");}
          | GT{$$= new QCString(" > ");}
          | GTEQ{$$= new QCString(" >= ");}
multiplying_op:
         MUL {$$ =  new QCString(" * ");}
        | DIV {$$ =  new QCString(" / ");}
        | MOD {$$ =  new QCString(" MOD ");}
        | REM {$$ =  new QCString(" REM ");}
            

                    
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
