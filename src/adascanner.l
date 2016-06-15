%{

#include<stdio.h>
#include<ctype.h>
#include "adaparser.tab.h"

%}


DIGIT			[0-9]
EXTENDED_DIGIT		[0-9a-zA-Z]
INTEGER			({DIGIT}(_?{DIGIT})*)
EXPONENT		([eE](\+?|-){INTEGER})
DECIMAL_LITERAL		{INTEGER}(\.?{INTEGER})?{EXPONENT}?
BASE			{INTEGER}
BASED_INTEGER		{EXTENDED_DIGIT}(_?{EXTENDED_DIGIT})*
BASED_LITERAL		{BASE}#{BASED_INTEGER}(\.{BASED_INTEGER})?#{EXPONENT}?
CHARACTER		[a-zA-Z](_?[a-zA-Z0-9])*

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
{CHARACTER}		return(resword(yytext));
"'"."'"			return(character_literal);
\"(\"\"|[^\n\"])*\"     return(string_literal);
{DECIMAL_LITERAL}	return(numerical);
{BASED_LITERAL}		return(numerical);
--.*\n			{getComment();};
[ \t\n\f]		;


%%

typedef struct
        {
        char    * kw;
        int     kwv;
        } KEY_TABLE;

# define NUM_KW  72


KEY_TABLE key_tab[NUM_KW] = {
                {"ABORT",       ABORT},
                {"ABS",         ABS},
		{"ABSTRACT",	ABSTRACT},
                {"ACCEPT",      ACCEPT},
                {"ACCESS",      ACCESS},
		{"ALIASED",	ALIASED},
                {"ALL",         ALL},
                {"AND",         AND},
                {"ARRAY",       ARRAY},
                {"AT",          AT},
                {"BEGIN",       BeGIN},
                {"BODY",        BODY},
                {"CASE",        CASE},
                {"CONSTANT",    CONSTANT},
                {"DECLARE",     DECLARE},
                {"DELAY",       DELAY},
                {"DELTA",       DELTA},
                {"DIGITS",      DIGITS},
                {"DO",          DO},
                {"ELSE",        ELSE},
                {"ELSIF",       ELSIF},
                {"END",         END},
                {"ENTRY",       ENTRY},
                {"EXCEPTION",   EXCEPTION},
                {"EXIT",        EXIT},
                {"FOR",         FOR},
                {"FUNCTION",    FUNCTION},
                {"GENERIC",     GENERIC},
                {"GOTO",        GOTO},
                {"IF",          IF},
                {"IN",          IN},
		{"INTERFACE",	INTERFACE},
                {"IS",          IS},
                {"LIMITED",     LIMITED},
                {"LOOP",        LOOP},
                {"MOD",         MOD},
                {"NEW",         NEW},
                {"NOT",         NOT},
                {"NULL",        Null},
                {"OF",          OF},
                {"OR",          OR},
                {"OTHERS",      OTHERS},
                {"OUT",         OUT},
		{"OVERRIDING",	OVERRIDING},
                {"PACKAGE",     PACKAGE},
                {"PRAGMA",      PRAGMA},
                {"PRIVATE",     PRIVATE},
                {"PROCEDURE",   PROCEDURE},
		{"PROTECTED",	PROTECTED},
                {"RAISE",       RAISE},
                {"RANGE",       RANGE},
                {"RECORD",      RECORD},
                {"REM",         REM},
                {"RENAMES",     RENAMES},
		{"REQUEUE",	REQUEUE},
                {"RETURN",      RETURN},
                {"REVERSE",     REVERSE},
                {"SELECT",      SELECT},
                {"SEPARATE",    SEPARATE},
                {"SUBTYPE",     SUBTYPE},
		{"SYNCHRONIZED",SYNCHRONIZED},
		{"TAGGED",	TAGGED},
                {"TASK",        TASK},
                {"TERMINATE",   TERMINATE},
                {"THEN",        THEN},
                {"TYPE",        TYPE},
		{"UNTIL",	UNTIL},
                {"USE",         USE},
                {"WHEN",        WHEN},
                {"WHILE",       WHILE},
                {"WITH",        WITH},
                {"XOR",         XOR}
                };
          

upper_string(char *str)
{
	while(*str != '\0')
	{
		*str = toupper(*str);
		str++;
	}
}

getComment()
{
	printf("%s",yytext);
}

getMLComment()
{
	printf("ML: %s", yytext);
}

resword(char *str) 
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
