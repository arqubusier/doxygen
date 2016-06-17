%{
#include <stdio.h>
#include <ctype.h>
#include <iostream>
#include "adaparser.tab.h"
#include "adaparser.h"

#define YY_DECL extern int adaYYlex()

%}


DIGIT			[0-9]
EXTENDED_DIGIT		[0-9a-zA-Z]
INTEGER			({DIGIT}(_?{DIGIT})*)
EXPONENT		([eE](\+?|-){INTEGER})
DECIMAL_LITERAL		{INTEGER}(\.?{INTEGER})?{EXPONENT}?
BASE			{INTEGER}
BASED_INTEGER		{EXTENDED_DIGIT}(_?{EXTENDED_DIGIT})*
BASED_LITERAL		{BASE}#{BASED_INTEGER}(\.{BASED_INTEGER})?#{EXPONENT}?
CH		[a-zA-Z](_?[a-zA-Z0-9])*

%%

"."			return('.');
"<"			return('<');
"("                     return('(');
"+"                     return('+');
"|"                     return('|');
"&"                     return('&');
"*"                     return('*');
")"                     return(')');
";"                     return(';');
"-"                     return('-');
"/"                     return('/');
","                     return(',');
">"                     return('>');
":"                     return(':');
"="                     return('=');
"'"			return(TIC);
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
{CH}			{
			  adaYYlval.charVal = *adaYYtext;
			  std::cout << "adascanner found" << adaYYlval.charVal << std::endl;
			  return(CHARACTER);
			}
"'"."'"			return(character_literal);
\"(\"\"|[^\n\"])*\"     return(string_literal);
{DECIMAL_LITERAL}	return(numerical);
{BASED_LITERAL}		return(numerical);
--.*\n			return('o');
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

/*
void resword(char *str) 
{
	int i;
	for(i = 0; i<NUM_KW; i++)
	{
		upper_string(str);
		if(!strcmp(key_tab[i].kw, str))
			{
			printf("KW: %s\n", str);
			return key_tab[i].kwv;
			}
	
	}
	printf("ID: %s\n", str);
      	return identifier;
}
*/
int adaYYwrap(){
	return 1;
}

bool AdaLanguageScanner::setFile(const char* fileName){
  adaYYin = fopen( yytext, "r" );
  inputFile.setName(fileName);
  if (inputFile.open(IO_ReadOnly))
  {
    yy_switch_to_buffer(yy_create_buffer(adaYYin, YY_BUF_SIZE));	
    return true;
  }
  inputFile.close();
  return false;
}

void AdaLanguageScanner::restartScanner(){
  adaYYrestart(adaYYin);	
}

void AdaLanguageScanner::cleanFile(){
  yy_delete_buffer( YY_CURRENT_BUFFER );
  inputFile.close();
}
