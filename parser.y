%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex(void);

// File pointers for output
FILE *debug_file;
FILE *tac_file;

// Symbol table for variables
#define MAX_SYMBOLS 100
struct {
    char *name;
    int value;
} symbol_table[MAX_SYMBOLS];
int symbol_count = 0;

// Temporary variable counter for three-address code
int temp_counter = 0;

// Function to get a new temporary variable name
char* new_temp() {
    char* temp = (char*)malloc(10);
    sprintf(temp, "t%d", temp_counter++);
    return temp;
}

// Function to get variable value
int get_variable(char *name) {
    for(int i = 0; i < symbol_count; i++) {
        if(strcmp(symbol_table[i].name, name) == 0) {
            return symbol_table[i].value;
        }
    }
    fprintf(debug_file, "Warning: Undefined variable %s\n", name);
    return 0; // Default value for undefined variables
}

// Function to set variable value
void set_variable(char *name, int value) {
    for(int i = 0; i < symbol_count; i++) {
        if(strcmp(symbol_table[i].name, name) == 0) {
            symbol_table[i].value = value;
            return;
        }
    }
    // Add new variable if not found
    if(symbol_count < MAX_SYMBOLS) {
        symbol_table[symbol_count].name = strdup(name);
        symbol_table[symbol_count].value = value;
        symbol_count++;
    }
}

// Global variable to store current input line
char current_line[1024];

// Structure to store statements
typedef struct {
    char *text;
    int value;
} Statement;

#define MAX_STATEMENTS 100
Statement statements[MAX_STATEMENTS];
int statement_count = 0;

void add_statement(const char *text, int value) {
    if (statement_count < MAX_STATEMENTS) {
        statements[statement_count].text = strdup(text);
        statements[statement_count].value = value;
        statement_count++;
    }
}

void execute_statements(int start, int end) {
    for (int i = start; i < end && i < statement_count; i++) {
        fprintf(debug_file, "%s\n", statements[i].text);
        printf("%s\n", statements[i].text);
    }
}

void clear_statements() {
    for (int i = 0; i < statement_count; i++) {
        free(statements[i].text);
    }
    statement_count = 0;
}
%}

%union {
    int num;
    char *str;
    int stmt_start;
}

%token <num> NUMBER
%token <str> IDENTIFIER STRING
%token PLUS MINUS MULTIPLY DIVIDE
%token ASSIGN PRINT IF ELSE TRUE FALSE
%token AND OR NOT
%token EQUALS NOTEQUALS GREATER LESS GREATEREQ LESSEQ
%token LBRACE RBRACE LPAREN RPAREN
%token SEMICOLON

%type <num> expr condition
%type <stmt_start> statements statement if_stmt else_part

%left OR
%left AND
%right NOT
%left PLUS MINUS
%left MULTIPLY DIVIDE

%%

program:
    { 
        debug_file = fopen("debug.txt", "w");
        tac_file = fopen("tac.txt", "w");
        if (!debug_file || !tac_file) {
            fprintf(stderr, "Error: Could not open output files\n");
            exit(1);
        }
        fprintf(debug_file, "=== Welcome to Surti Compiler ===\n\n");
        fprintf(tac_file, "=== Three Address Code ===\n\n");
        printf("=== Welcome to Surti Compiler ===\n\n");
    }
    statements
    { 
        fprintf(debug_file, "\n=== Chalni ja aave ===\n\n");
        fprintf(tac_file, "\n=== End of Three Address Code ===\n\n");
        printf("\n=== Chalni ja aave ===\n\n");
        clear_statements();
        fclose(debug_file);
        fclose(tac_file);
    }
    ;

statements:
    /* empty */ { $$ = statement_count; }
    | statements statement { $$ = $1; }
    ;

statement:
    PRINT expr SEMICOLON    { 
        char buf[256];
        snprintf(buf, sizeof(buf), "%d", $2);
        add_statement(buf, $2);
        fprintf(debug_file, "Input: chalni_lakh %d;\n", $2);
        fprintf(tac_file, "print t%d\n", $2);
        $$ = statement_count - 1;
    }
    | PRINT STRING SEMICOLON {
        add_statement($2, 0);
        fprintf(debug_file, "Input: chalni_lakh %s;\n", $2);
        fprintf(tac_file, "print %s\n", $2);
        $$ = statement_count - 1;
    }
    | IDENTIFIER ASSIGN expr SEMICOLON  { 
        fprintf(debug_file, "Input: %s = %d;\n", $1, $3);
        fprintf(tac_file, "%s = t%d\n", $1, $3);
        set_variable($1, $3); 
        $$ = statement_count;
    }
    | if_stmt { $$ = $1; }
    ;

if_stmt:
    IF condition {
        $<num>$ = statement_count;
        fprintf(tac_file, "if t%d == 0 goto L%d\n", $2, temp_counter);
        int label = temp_counter++;
        fprintf(tac_file, "goto L%d\n", temp_counter);
        fprintf(tac_file, "L%d:\n", label);
    } LBRACE statements RBRACE else_part {
        fprintf(tac_file, "L%d:\n", temp_counter);
        if ($2) {
            execute_statements($<num>3, statement_count);
        } else if ($7 >= 0) {
            execute_statements($7, statement_count);
        }
        $$ = statement_count;
    }
    ;

else_part:
    /* empty */ { $$ = -1; }
    | ELSE LBRACE {
        $<num>$ = statement_count;
    } statements RBRACE {
        $$ = $<num>3;
    }
    ;

condition:
    expr EQUALS expr    { 
        char *temp = new_temp();
        fprintf(tac_file, "%s = t%d == t%d\n", temp, $1, $3);
        $$ = temp_counter - 1;
    }
    | expr NOTEQUALS expr { 
        char *temp = new_temp();
        fprintf(tac_file, "%s = t%d != t%d\n", temp, $1, $3);
        $$ = temp_counter - 1;
    }
    | expr GREATER expr { 
        char *temp = new_temp();
        fprintf(tac_file, "%s = t%d > t%d\n", temp, $1, $3);
        $$ = temp_counter - 1;
    }
    | expr LESS expr    { 
        char *temp = new_temp();
        fprintf(tac_file, "%s = t%d < t%d\n", temp, $1, $3);
        $$ = temp_counter - 1;
    }
    | expr GREATEREQ expr { 
        char *temp = new_temp();
        fprintf(tac_file, "%s = t%d >= t%d\n", temp, $1, $3);
        $$ = temp_counter - 1;
    }
    | expr LESSEQ expr  { 
        char *temp = new_temp();
        fprintf(tac_file, "%s = t%d <= t%d\n", temp, $1, $3);
        $$ = temp_counter - 1;
    }
    | TRUE             { 
        char *temp = new_temp();
        fprintf(tac_file, "%s = 1\n", temp);
        $$ = temp_counter - 1;
    }
    | FALSE            { 
        char *temp = new_temp();
        fprintf(tac_file, "%s = 0\n", temp);
        $$ = temp_counter - 1;
    }
    | condition AND condition { 
        char *temp = new_temp();
        fprintf(tac_file, "%s = t%d && t%d\n", temp, $1, $3);
        $$ = temp_counter - 1;
    }
    | condition OR condition  { 
        char *temp = new_temp();
        fprintf(tac_file, "%s = t%d || t%d\n", temp, $1, $3);
        $$ = temp_counter - 1;
    }
    | NOT condition     { 
        char *temp = new_temp();
        fprintf(tac_file, "%s = !t%d\n", temp, $2);
        $$ = temp_counter - 1;
    }
    | LPAREN condition RPAREN { $$ = $2; }
    ;

expr:
    NUMBER { 
        $$ = $1;
        char *temp = new_temp();
        fprintf(tac_file, "%s = %d\n", temp, $1);
        $$ = temp_counter - 1;
    }
    | IDENTIFIER { 
        $$ = get_variable($1);
        char *temp = new_temp();
        fprintf(tac_file, "%s = %s\n", temp, $1);
        $$ = temp_counter - 1;
    }
    | expr PLUS expr { 
        char *temp = new_temp();
        fprintf(tac_file, "%s = t%d + t%d\n", temp, $1, $3);
        $$ = temp_counter - 1;
    }
    | expr MINUS expr { 
        char *temp = new_temp();
        fprintf(tac_file, "%s = t%d - t%d\n", temp, $1, $3);
        $$ = temp_counter - 1;
    }
    | expr MULTIPLY expr { 
        char *temp = new_temp();
        fprintf(tac_file, "%s = t%d * t%d\n", temp, $1, $3);
        $$ = temp_counter - 1;
    }
    | expr DIVIDE expr { 
        char *temp = new_temp();
        fprintf(tac_file, "%s = t%d / t%d\n", temp, $1, $3);
        $$ = temp_counter - 1;
    }
    | LPAREN expr RPAREN { $$ = $2; }
    ;

%%

void yyerror(const char *s) {
    fprintf(debug_file, "Error: %s\n", s);
}

int main(void) {
    yyparse();
    return 0;
} 