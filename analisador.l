%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"

/* Variáveis globais para rastrear linha atual */
char current_line[1024];
int current_pos = 0;

/* Variáveis para controle de posição */
extern YYLTYPE yylloc;
int current_column = 1;

/* Macro para atualizar posição */
#define UPDATE_YYLLOC() \
    do { \
        yylloc.first_line = yylineno; \
        yylloc.first_column = current_column; \
        yylloc.last_line = yylineno; \
        yylloc.last_column = current_column + yyleng - 1; \
        current_column += yyleng; \
        /* copia token para current_line, se couber */ \
        for (int i = 0; i < yyleng && current_pos < sizeof(current_line) - 1; i++) { \
            current_line[current_pos++] = yytext[i]; \
        } \
        current_line[current_pos] = '\0'; \
    } while (0)

%}

%option noyywrap yylineno

%%

"begin"             { UPDATE_YYLLOC(); return KEY_BEGIN; }
"end"               { UPDATE_YYLLOC(); return KEY_END; }
"if"                { UPDATE_YYLLOC(); return KEY_IF; }
"else"              { UPDATE_YYLLOC(); return KEY_ELSE; }
"while"             { UPDATE_YYLLOC(); return KEY_WHILE; }
"for"               { UPDATE_YYLLOC(); return KEY_FOR; }
"step_by"           { UPDATE_YYLLOC(); return FUNC_STEP_BY; }
"do"                { UPDATE_YYLLOC(); return KEY_DO; }
"in"                { UPDATE_YYLLOC(); return KEY_IN; }
"const"             { UPDATE_YYLLOC(); return KEY_CONST; }
"function"          { UPDATE_YYLLOC(); return KEY_FUNCTION; }
"return"            { UPDATE_YYLLOC(); return KEY_RETURN; }
"true"              { UPDATE_YYLLOC(); return KEY_TRUE; }
"false"             { UPDATE_YYLLOC(); return KEY_FALSE; }
"input"             { UPDATE_YYLLOC(); return FUNC_INPUT; }
"output"            { UPDATE_YYLLOC(); return FUNC_OUTPUT; }
"outputln"          { UPDATE_YYLLOC(); return FUNC_OUTPUTLN; }
"and"               { UPDATE_YYLLOC(); return OP_AND; }
"or"                { UPDATE_YYLLOC(); return OP_OR; }
"not"               { UPDATE_YYLLOC(); return OP_NOT; }
"raise"             { UPDATE_YYLLOC(); return KEY_RAISE; }
"try"               { UPDATE_YYLLOC(); return KEY_TRY; }
"except"            { UPDATE_YYLLOC(); return KEY_EXCEPT; }
"finally"           { UPDATE_YYLLOC(); return KEY_FINALLY; }
"exception"         { UPDATE_YYLLOC(); return KEY_EXCEPTION; }
"break"             { UPDATE_YYLLOC(); return KEY_BREAK; }
"continue"          { UPDATE_YYLLOC(); return KEY_CONTINUE; }
"exit"              { UPDATE_YYLLOC(); return KEY_EXIT; }
"type"              { UPDATE_YYLLOC(); return KEY_TYPE; }
"record"            { UPDATE_YYLLOC(); return KEY_RECORD; }
"allocate"          { UPDATE_YYLLOC(); return FUNC_ALLOCATE; }
"free"              { UPDATE_YYLLOC(); return FUNC_FREE; }
"size"              { UPDATE_YYLLOC(); return FUNC_SIZE; }
"read"              { UPDATE_YYLLOC(); return FUNC_READ; }
"write"             { UPDATE_YYLLOC(); return FUNC_WRITE; }
"append"            { UPDATE_YYLLOC(); return FUNC_APPEND; }
"close"             { UPDATE_YYLLOC(); return FUNC_CLOSE; }

"int"               { UPDATE_YYLLOC(); return TYPE_INTEGER; }
"real"              { UPDATE_YYLLOC(); return TYPE_REAL; }
"decimal"           { UPDATE_YYLLOC(); return TYPE_DECIMAL; }
"boolean"           { UPDATE_YYLLOC(); return TYPE_BOOLEAN; }
"char"              { UPDATE_YYLLOC(); return TYPE_CHAR; }
"string"            { UPDATE_YYLLOC(); return TYPE_STRING; }
"date"              { UPDATE_YYLLOC(); return TYPE_DATE; }
"time"              { UPDATE_YYLLOC(); return TYPE_TIME; }
"void"              { UPDATE_YYLLOC(); return TYPE_VOID; }
"dict"              { UPDATE_YYLLOC(); return TYPE_DICT; }
"set"               { UPDATE_YYLLOC(); return TYPE_SET; }

":="                { UPDATE_YYLLOC(); return OP_ASSIGN; }
"+="                { UPDATE_YYLLOC(); return OP_PLUS_ASSIGN; }
"-="                { UPDATE_YYLLOC(); return OP_MINUS_ASSIGN; }
"*="                { UPDATE_YYLLOC(); return OP_MUL_ASSIGN; }
"/="                { UPDATE_YYLLOC(); return OP_DIV_ASSIGN; }
"%="                { UPDATE_YYLLOC(); return OP_MOD_ASSIGN; }

"<>"                { UPDATE_YYLLOC(); return OP_NE ; } 
"<="                { UPDATE_YYLLOC(); return OP_LE ; }
">="                { UPDATE_YYLLOC(); return OP_GE ; }
"="                 { UPDATE_YYLLOC(); return OP_EQ ; }
"<"                 { UPDATE_YYLLOC(); return OP_LT ; }
">"                 { UPDATE_YYLLOC(); return OP_GT ; }

"+"                 { UPDATE_YYLLOC(); return OP_PLUS; }
"-"                 { UPDATE_YYLLOC(); return OP_MINUS; }
"*"                 { UPDATE_YYLLOC(); return OP_MULTIPLY; }
"/"                 { UPDATE_YYLLOC(); return OP_DIVIDE; }
"div"               { UPDATE_YYLLOC(); return OP_INT_DIVIDE ; }
"%"                 { UPDATE_YYLLOC(); return OP_MOD; }

"("                 { UPDATE_YYLLOC(); return L_PAREN; }
")"                 { UPDATE_YYLLOC(); return R_PAREN; }
"["                 { UPDATE_YYLLOC(); return L_BRACKET; }
"]"                 { UPDATE_YYLLOC(); return R_BRACKET; }
"{"                 { UPDATE_YYLLOC(); return L_BRACE; }
"}"                 { UPDATE_YYLLOC(); return R_BRACE; }
":"                 { UPDATE_YYLLOC(); return COLON; }
";"                 { UPDATE_YYLLOC(); return SEMICOLON; }
".."                { UPDATE_YYLLOC(); return OP_RANGE; }
","                 { UPDATE_YYLLOC(); return COMMA; }
"."                 { UPDATE_YYLLOC(); return DOT; }

[0-9]+              { UPDATE_YYLLOC(); yylval.sValue = strdup(yytext); return LIT_INT; }
[0-9]+"."[0-9]+     { UPDATE_YYLLOC(); yylval.sValue = strdup(yytext); return LIT_REAL; }
[a-zA-Z_][a-zA-Z0-9_]* { UPDATE_YYLLOC(); yylval.sValue = strdup(yytext); return ID; }
\"([^"\n\\]|\\.)*\" { UPDATE_YYLLOC(); yylval.sValue = strdup(yytext); return LIT_STRING; }

\n {
    current_line[current_pos] = '\0';
    current_pos = 0;
    current_column = 1;
}

[ \t\r]+   { current_column += yyleng; /* ignora espaços */ }

"//".*              { /* ignora comentário de linha */ }
"/*"([^*]|\n)*"*/"   { /* ignora comentário de bloco */ }

. {
    UPDATE_YYLLOC();
    current_line[current_pos++] = yytext[0];
    if (current_pos < sizeof(current_line) - 1)
        current_line[current_pos] = '\0';
    return yytext[0];
}

%%

