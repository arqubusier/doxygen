%{
#include <stdio.h>
#include <ctype.h>
#include <iostream>
//the hpp file contains the tokens
#include "adaparser.hpp"
#include "adaparser.h"

#define YY_DECL extern int adaYYlex()

/*
 Static variables
 */
static const char *     inputString;
static int		        inputPosition;
YY_BUFFER_STATE         s_bufferState;

/*
 the file contents is read by doxygen before scanning.
 */
 /*
//#undef	YY_INPUT
//#define	YY_INPUT(buf,result,max_size) result=yyread(buf,max_size);
static int yyread(char *buf, int max_size){
  int c=0;
  while ( c < max_size && inputString[inputPosition] )
  {
    *buf = inputString[inputPosition++] ;
    printf("%d (%c)\n",*buf,*buf);
    c++; buf++;
  }
  return c;
    
}
*/

void setInputString(const char *input)
{
  s_bufferState = yy_scan_string(input);
}

void cleanupInputString(){
  yy_delete_buffer(s_bufferState);
}
%}


DIGIT			[0-9]
EXTENDED_DIGIT		[0-9a-zA-Z]
INTEGER			({DIGIT}(_?{DIGIT})*)
EXPONENT		([eE](\+?|-){INTEGER})
DECIMAL_LITERAL		{INTEGER}(\.?{INTEGER})?{EXPONENT}?
BASE			{INTEGER}
BASED_INTEGER		{EXTENDED_DIGIT}(_?{EXTENDED_DIGIT})*
BASED_LITERAL		{BASE}#{BASED_INTEGER}(\.{BASED_INTEGER})?#{EXPONENT}?

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
"'"."'"			return(character_literal);
\"(\"\"|[^\n\"])*\"     return(string_literal);
{DECIMAL_LITERAL}	return(numerical);
{BASED_LITERAL}		return(numerical);
"--[^\n!]*\n"			{std::cout << "skipping comment" << std::endl;}
"--!"                 {BEGIN(comment);}
<comment>[^\n]*     {adaYYlval.cstrVal = strdup(adaYYtext);
                     return(COMMENT_BODY);}
<comment>\n         {BEGIN(INITIAL);} 
[ \t\n\f]		;


%%

void upper_string(char *str)
{
	while(*str != '\0')
	{
		*str = toupper(*str);
		str++;
	}
}

void getComment()
{
	printf("%s",yytext);
}

void getMLComment()
{
	printf("ML: %s", yytext);
}
int adaYYwrap(){
	return 1;
}
