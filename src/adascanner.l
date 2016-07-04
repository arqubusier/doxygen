%{
#include <stdio.h>
#include <ctype.h>
#include <iostream>
//the hpp file contains the tokens
#include "adaparser.h"
#include "adaparser.hpp"
#include "entry.h"
#include "commentscan.h"
#include "message.h"

#define YY_DECL extern int adaYYlex()

/*
 Static variables
 */
static const char *     inputString;
static int		        inputPosition;
static QCString         s_specialComment;
static AdaLanguageScanner *s_parser;
static QCString         s_fileName;
YY_BUFFER_STATE         s_bufferState;

/*
 Global variables
*/
Entry* parser_root;

/*
 the file contents is read by doxygen before scanning.
 */

void setInputString(const char *input)
{
  s_bufferState = yy_scan_string(input);
}

void cleanupInputString(){
  yy_delete_buffer(s_bufferState);
}

void handleComment(Entry *non_struct_entry,
              bool  &is_non_struct,
              const QCString &doc);

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

%x doxy_comment
%x comment


%%

"'"			    return(TIC);
".."			return(DDOT);
"<<"			return(MLT);
"<>"			return(BOX);
"<="			return(LTEQ);
"**"			return(EXP);
"/="			return(NEQ);
">>"			return(MGT);
">="			return(GTEQ);
":="			return(ASS);
"=>"			return(REF);
";"             return(SEM);
","             return(COMMA);
":"             {printf("colon\n");return(COLON);}
"package"       {printf("package\n");return(PACKAGE);}
"is"            {printf("is\n");return(IS);}
"end"           {printf("end\n");return(END);}
"--!"                 {s_specialComment.resize(0); 
                       printf("start doxycomment\n");
                       BEGIN(doxy_comment);}
<doxy_comment>[^\n]*  {s_specialComment.append(adaYYtext);}
<doxy_comment>"\n--!" {s_specialComment.append("\n");} 

<doxy_comment>"\n"    {/*Structural comments no not depend
                        on location in the syntax tree, and
                        are thus handeled by the lexer.
                        
                        Non-structural comments o.t.h. are
                        handeled by the parser.*/
                       BEGIN(INITIAL);
                       printf("end doxycomment\n");
                       Entry *entry = new Entry;
                       bool is_non_struct;
                       handleComment(entry, is_non_struct,
                                    s_specialComment);
                       if (is_non_struct)
                       {
                         adaYYlval.entryPtr = entry;
                         return SPECIAL_COMMENT;
                       }
                      }
"--"                 {BEGIN(comment);}
<comment>[^\n]*     ;
<comment>\n         {BEGIN(INITIAL);printf("end comment\n");}
[a-zA-Z][a-zA-Z0-9_]* {printf("id\n");
                        adaYYlval.cstrVal = strdup(adaYYtext);
                        return(IDENTIFIER);}
[ \t\n\f]		;


%%

void handleComment(Entry *non_struct_entry,
              bool  &is_non_struct,
              const QCString &doc)
{
  int pos=0;
  int lineNum=0;
  Protection protection = Public;
  bool newEntryNeeded;
  Entry *current = non_struct_entry;

  is_non_struct = true;
  while (parseCommentBlock(
           s_parser,
           current,
           doc,
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
      parser_root->addSubEntry(current);
      current = new Entry;
    }
  }
  if (newEntryNeeded){
      is_non_struct = false;
      parser_root->addSubEntry(current);
      current = new Entry;
  }
}

void initAdaScanner(AdaLanguageScanner *parser, QCString fileName,
                    Entry *root){
  parser_root = root;
  s_fileName = fileName;
  s_parser = parser;
}

void upper_string(char *str)
{
	while(*str != '\0')
	{
		*str = toupper(*str);
		str++;
	}
}

void freeAdaScanner()
{
  s_parser = NULL;
}

int adaYYwrap(){
	return 1;
}
