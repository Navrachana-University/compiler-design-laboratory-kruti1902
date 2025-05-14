%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"

// File pointer for debug output
extern FILE *debug_file;

// Buffer to store the complete condition
static char condition_buffer[1024];
static int buffer_pos = 0;

static void add_to_condition(const char* text) {
    if (buffer_pos < sizeof(condition_buffer) - 1) {
        strcat(condition_buffer, text);
        buffer_pos += strlen(text);
    }
}

static void clear_condition() {
    condition_buffer[0] = '\0';
    buffer_pos = 0;
}

static void print_condition() {
    if (buffer_pos > 0) {
        fprintf(debug_file, "Input: %s\n", condition_buffer);
        clear_condition();
    }
}
%}

%%
[0-9]+          { 
    yylval.num = atoi(yytext); 
    add_to_condition(yytext);
    add_to_condition(" ");
    return NUMBER; 
}
\"[^\"]*\"      { yylval.str = strdup(yytext); return STRING; }
"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return MULTIPLY; }
"/"             { return DIVIDE; }
"="             { return ASSIGN; }
";"             { return SEMICOLON; }
"chalni_lakh"   { return PRINT; }
"jo_ben"        { 
    clear_condition();
    add_to_condition("jo_ben ");
    return IF; 
}
"nai_to_ben"    { 
    fprintf(debug_file, "Input: nai_to_ben\n");
    return ELSE; 
}
"sachu_che"     { return TRUE; }
"khotu_che"     { return FALSE; }
"aane"          { add_to_condition("aane "); return AND; }
"athwa"         { add_to_condition("athwa "); return OR; }
"aa_nai"        { add_to_condition("aa_nai "); return NOT; }
"=="            { add_to_condition("== "); return EQUALS; }
"!="            { add_to_condition("!= "); return NOTEQUALS; }
">"             { add_to_condition("> "); return GREATER; }
"<"             { add_to_condition("< "); return LESS; }
">="            { add_to_condition(">= "); return GREATEREQ; }
"<="            { add_to_condition("<= "); return LESSEQ; }
"{"             { 
    print_condition();
    return LBRACE; 
}
"}"             { return RBRACE; }
"("             { add_to_condition("("); return LPAREN; }
")"             { add_to_condition(")"); return RPAREN; }
[a-zA-Z][a-zA-Z0-9_]*  { 
    yylval.str = strdup(yytext); 
    add_to_condition(yytext);
    add_to_condition(" ");
    return IDENTIFIER; 
}
[ \t\n]         ; /* Skip whitespace */
.               { printf("Unexpected character: %s\n", yytext); }
%%

int yywrap(void) {
    return 1;
} 