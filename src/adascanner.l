%{
#include <stdio.h>
#include <ctype.h>
#include <iostream>
//the hpp file contains the tokens
#include "adaparser.h"
#include "adaparser.hpp"

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
"package"       {printf("package\n");return(PACKAGE);}
"is"            {printf("is\n");return(IS);}
"end"           {printf("end\n");return(END);}
"--!"                 {BEGIN(doxy_comment);}
<doxy_comment>[^\n]*     {adaYYlval.cstrVal = strdup(adaYYtext);
                     return(COMMENT_BODY);}
<doxy_comment>\n         {BEGIN(INITIAL);printf("end doxycomment\n");} 
"--"                 {BEGIN(comment);}
<comment>[^\n]*     ;
<comment>\n         {BEGIN(INITIAL);printf("end comment\n");}
[:alpha:][[:alnum:]_]* {printf("id\n");
                        adaYYlval.cstrVal = strdup(adaYYtext);
                        return(IDENTIFIER);}
[ \t\n\f]		;


%%
/*
"'"."'"			return(character_literal);
\"(\"\"|[^\n\"])*\"     return(string_literal);

*/

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
