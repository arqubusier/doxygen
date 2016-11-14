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


/** \file adascanner.l
 * \brief Ada scanner (lexer) in flex format.
 */

%{
#include <stdio.h>
#include <ctype.h>
#include <iostream>
#include "adaparser.h"
//the hpp file contains the tokens
#include "adaparser.hpp"
#include "entry.h"
#include "commentscan.h"
#include "message.h"

#define TEXT_TO_QSTR adaYYlval.qstrPtr = new QCString(yytext)

/*
 Static variables
 */
static const char         *inputString;
static int		           inputPosition;
static QCString            s_specialComment;
static AdaLanguageScanner *s_parser;
static QCString            s_fileName;
YY_BUFFER_STATE            s_bufferState;
static Entries             s_structDoxyComments;
static bool                s_should_save_comments;

/*
* Global variables
*/
Entry* parser_root;


/*
* Helper functions.
*/
void handleComment(EntryNode *non_struct_entry,
              bool  &is_non_struct);
void resetStructDoxyComments();

/* visible functions */
void adaScannerCleanup()
{
  resetStructDoxyComments();
  cleanupInputString();
}
void setInputString(const char *input)
{
  s_bufferState = yy_scan_string(input);
}

void cleanupInputString(){
  yy_delete_buffer(s_bufferState);
}

%}
%option caseless

DIGIT			[0-9]
EXTENDED_DIGIT		[0-9a-zA-Z]
INTEGER			({DIGIT}(_?{DIGIT})*)
EXPONENT		([eE](\+?|-){INTEGER})
DECIMAL_LITERAL		{INTEGER}(\.?{INTEGER})?{EXPONENT}?
BASE			{INTEGER}
BASED_INTEGER		{EXTENDED_DIGIT}(_?{EXTENDED_DIGIT})*
BASED_LITERAL		{BASE}#{BASED_INTEGER}(\.{BASED_INTEGER})?#{EXPONENT}?
STRING_CHAR     ([^'"]|\\.)
STRING_LITERAL  \"{STRING_CHAR}*\"
B       [ \t]


%x doxy_comment
%x comment


%%
{STRING_LITERAL}  {TEXT_TO_QSTR; return(STRING_LITERAL);}
{INTEGER}         {TEXT_TO_QSTR; return(INTEGER);}
{DECIMAL_LITERAL} {TEXT_TO_QSTR; return(DECIMAL_LITERAL);}
{BASED_LITERAL}   {TEXT_TO_QSTR; return(BASED_LITERAL);}
"delay"         return(DELAY);
"delta"         return(DELTA);
"declare"       return(DECLARE);
"overriding"    return(OVERRIDING);
"renames"       return(RENAMES);
"raise"         return(RAISE);
"with"          return(WITH);
"goto"          return(GOTO);
"separate"      return(SEPARATE);
"generic"       return(GENERIC);
"abort"         return(ABORT);
"access"        return(ACCESS);
"true"          {return(True);}
"false"          {return(False);}
"|"             {return(PIPE);}
"aliased"       {return(ALIASED);}
"<>"            {return(BOX);}
"range"         {return(RANGE);}
"array"         {return(ARRAY);}
"and"           {return(AND);}
"or"            {return(OR);}
"xor"           {return(XOR);}
"*"             return(MUL);
"+"             return(ADD);
"-"             return(MINUS);
"&"             return(AMB);
"/"             return(DIV);
"mod"           return(MOD);
"rem"           return(REM);
"abs"           return(ABS);
"not"           return(NOT);
"exit"          return(EXIT);
"if"            return(IF);
"then"          return(THEN);
"elsif"         return(ELSIF);
"else"          return(ELSE);
"case"          return(CASE);
"when"          return(WHEN);
"others"        return(OTHERS);
"loop"          return(LOOP);
"while"         return(WHILE);
"for"           return(FOR);
"reverse"       return(REVERSE);
"use"           return(USE);
"of"            return(OF);
"'"			    return(TIC);
".."			return(DDOT);
"."             return(DOT);
"<<"			return(MLT);
"<="			return(LTEQ);
"**"			return(EXP);
"/="			return(NEQ);
">>"			return(MGT);
">="			return(GTEQ);
"<"             return(LT);
">"             return(GT);
"="			    return(EQ);
":="			return(ASS);
"=>"			return(REF);
";"             return(SEM);
","             return(COMMA);
":"             {return(COLON);}
"new"           return(NEW);
"all"           return(ALL);
"constant"      return(CONSTANT);
"package"{B}*"body"  {return(PACKAGE_BODY);}
"package"  {return(PACKAGE);}
"private"       {return(PRIVATE);}
"protected"       {return(PROTECTED_);}
"is"            {return(IS);}
"end"           {return(END);}
"in"            {return(IN);}
"out"           {return(OUT);}
"procedure"     {return(PROCEDURE);}
"function"      {return(FUNCTION);}
"return"        {return(RETURN);}
"type"          {return(TYPE);}
"record"        {return(RECORD);}
"tagged"        {return(TAGGED);}
"abstract"      {return(ABSTRACT);}
")"          {return(RPAR);}
"("          {return(LPAR);}
"begin"          {return(BEGIN_);}
"null"          {return(Null);}
"--!"                 {s_specialComment.resize(0); 
                       BEGIN(doxy_comment);}
<doxy_comment>[^\n]*  {s_specialComment.append(yytext);}
<doxy_comment>\n{B}*"--!" {s_specialComment.append("\n");}

<doxy_comment>\n    {
                       BEGIN(INITIAL);
                       if (s_should_save_comments)
                       {
                         EntryNode *entry = new EntryNode;
                         bool is_non_struct;
                         handleComment(entry, is_non_struct);
                         if (is_non_struct)
                         {
                           adaYYlval.nodePtr = entry;
                           return SPECIAL_COMMENT;
                         }
                       }
                      }
"--"                 {BEGIN(comment);}
<comment>[^\n]*     ;
<comment>\n         {BEGIN(INITIAL);}
[a-zA-Z][a-zA-Z0-9_]* {adaYYlval.cstrVal = strdup(yytext);
                        return(IDENTIFIER);}
[ \t\n\f]		;


%%
const Entries &getStructDoxyComments()
{
  return s_structDoxyComments;
}

void resetStructDoxyComments()
{
  s_structDoxyComments.resize(0);
}

void handleComment(EntryNode *non_struct_entry,
                   bool  &is_non_struct)
{
  int pos=0;
  int lineNum=0;
  Protection protection = Public;
  bool newEntryNeeded;
  EntryNode *current = non_struct_entry;


  is_non_struct = true;
  while (parseCommentBlock(
           s_parser,
           &current->entry,
           s_specialComment,
           s_fileName,
           lineNum,
           false,
           false,
           false,
           protection,
           pos,
           newEntryNeeded))
  {
    if (newEntryNeeded){
      is_non_struct = false;
      s_structDoxyComments.push_back(current);
      current = new EntryNode;
    }
  }
  if (newEntryNeeded){
    is_non_struct = false;
    s_structDoxyComments.push_back(current);
  }
}

void initAdaScanner(AdaLanguageScanner *parser, QCString fileName,
                    bool should_save_comments){

  s_parser = parser;
  s_fileName = fileName;
  s_should_save_comments = should_save_comments;
}

void upper_string(char *str)
{
	while(*str != '\0')
	{
		*str = toupper(*str);
		str++;
	}
}

void adaFreeScanner()
{
  s_parser = NULL;
}

int adaYYwrap(){
	return 1;
}
