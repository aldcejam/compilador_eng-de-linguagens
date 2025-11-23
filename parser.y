/* ========================================================================
   SEÇÃO DE DECLARAÇÕES EM C
   Esta seção é copiada literalmente para o arquivo C final gerado pelo Bison.
   Aqui declaramos bibliotecas, funções auxiliares, variáveis globais e
   elementos usados tanto pelo parser quanto pelo lexer.
   ======================================================================== */
%{
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/* Função do analisador léxico gerada pelo Flex */
int yylex(void);

/* Função padrão chamada quando ocorre um erro sintático */
void yyerror(const char *s);

/* Variáveis externas usadas para criar mensagens de erro mais detalhadas */
extern char current_line[1024];  // Linha atual do código fonte em análise
extern int current_pos;          // Posição atual do caractere na linha

/* Contador de erros sintáticos acumulados */
int syntax_errors = 0;
%}

/* ========================================================================
   SEÇÃO DE DECLARAÇÕES DO BISON
   Aqui declaramos tokens, tipos de dados, precedências e o símbolo inicial.
   ======================================================================== */

/* Union usada para armazenar valores associados a tokens */
%union {
    char *sValue;   // Apenas strings para simplificar o manipulador semântico
}

/* ---------------------- TOKENS QUE POSSUEM VALOR ------------------------ */
%token <sValue> ID
%token <sValue> LIT_INT
%token <sValue> LIT_REAL
%token <sValue> LIT_STRING

/* ---------------------- TOKENS SEM VALORES ------------------------------ */
%token LIT_NULL
%token KEY_TRUE KEY_FALSE

/* Palavras-chave de controle */
%token KEY_BEGIN KEY_END KEY_IF KEY_DO KEY_ELSE KEY_WHILE KEY_FOR KEY_IN
%token KEY_FUNCTION KEY_RETURN KEY_CONST KEY_BREAK KEY_CONTINUE KEY_EXIT

/* Tipos de dados */
%token TYPE_INTEGER TYPE_REAL TYPE_DECIMAL TYPE_BOOLEAN TYPE_CHAR TYPE_STRING 
%token TYPE_DATE TYPE_TIME TYPE_DICT TYPE_SET TYPE_VOID

/* Operadores de atribuição */
%token OP_ASSIGN OP_PLUS_ASSIGN OP_MINUS_ASSIGN OP_MUL_ASSIGN OP_DIV_ASSIGN OP_MOD_ASSIGN 

/* Operadores de comparação */
%token OP_EQ OP_NE OP_LE OP_GE OP_LT OP_GT 

/* Operadores aritméticos */
%token OP_PLUS OP_MINUS OP_MULTIPLY OP_INT_DIVIDE OP_DIVIDE OP_MOD OP_RANGE 

/* Operadores lógicos */
%token OP_AND OP_OR OP_NOT 

/* Símbolos */
%token L_PAREN R_PAREN L_BRACKET R_BRACKET L_BRACE R_BRACE 
%token COLON SEMICOLON COMMA DOT 

/* Funções especiais */
%token FUNC_STEP_BY
%token FUNC_INPUT FUNC_OUTPUT FUNC_OUTPUTLN

/* Controle de exceções */
%token KEY_RAISE KEY_TRY KEY_EXCEPT KEY_FINALLY KEY_EXCEPTION

/* Definição de tipos customizados */
%token KEY_TYPE KEY_RECORD

/* Funções do sistema */
%token FUNC_ALLOCATE FUNC_FREE FUNC_SIZE FUNC_READ FUNC_WRITE FUNC_APPEND FUNC_CLOSE

/* ========================================================================
   PRECEDÊNCIA E ASSOCIATIVIDADE DOS OPERADORES
   Ordena operadores para evitar ambiguidades e reduzir conflitos shift/reduce.
   ======================================================================== */
%left OP_OR
%left OP_AND
%left OP_EQ OP_NE OP_LT OP_LE OP_GT OP_GE
%left OP_PLUS OP_MINUS
%left OP_MULTIPLY OP_DIVIDE OP_INT_DIVIDE OP_MOD
%right OP_NOT
%right COLON

/* Resolução do "dangling else" utilizando não associatividade */
%nonassoc KEY_DO
%nonassoc KEY_ELSE

/* Permite rastrear linha e coluna nas mensagens de erro */
%locations

/* Define o ponto inicial da gramática */
%start prog

%%

/* ========================================================================
   REGRAS DA GRAMÁTICA
   Sintaxe formal da linguagem.
   ======================================================================== */

/* ---------------------- PROGRAMA PRINCIPAL ------------------------------ */
prog 
    : stmt_list
    ;

/* Lista de statements */
stmt_list 
    : stmt_list stmt
    | stmt
    ;

/* ---------------------- STATEMENTS GERAIS ------------------------------- */
stmt 
    : assign_stmt SEMICOLON
    | if_stmt
    | while_stmt
    | for_stmt
    | func_decl
    | func_call SEMICOLON
    | io_stmt SEMICOLON
    | block
    | KEY_BREAK SEMICOLON
    | KEY_CONTINUE SEMICOLON
    | KEY_RETURN expression SEMICOLON
    | KEY_RETURN SEMICOLON
    | KEY_EXIT SEMICOLON
    | error SEMICOLON
    ;

/* ---------------------- ENTRADA E SAÍDA -------------------------------- */
io_stmt
    : FUNC_INPUT '(' ID ')'
    | FUNC_OUTPUT '(' expr_list ')'
    ;

expr_list
    : expression
    | expr_list ',' expression
    ;

/* ---------------------- BLOCOS BEGIN ... END --------------------------- */
block 
    : KEY_BEGIN stmt_or_decl_list KEY_END
    ;

stmt_or_decl_list
    : stmt_or_decl_list stmt_or_decl
    | stmt_or_decl
    ;

stmt_or_decl
    : stmt
    | var_decl SEMICOLON
    ;

/* ---------------------- DECLARAÇÕES DE VARIÁVEIS ----------------------- */
var_decl 
    : ID COLON type
    | ID COLON type OP_ASSIGN expression
    | KEY_CONST ID COLON type OP_ASSIGN expression
    ;

/* ---------------------- ATRIBUIÇÕES ------------------------------------ */
lvalue
    : ID
    | ID L_BRACKET expression R_BRACKET
    | ID L_BRACKET expression R_BRACKET L_BRACKET expression R_BRACKET
    ;

assign_stmt 
    : lvalue OP_ASSIGN expression
    | lvalue OP_PLUS_ASSIGN expression
    | lvalue OP_MINUS_ASSIGN expression
    | lvalue OP_MUL_ASSIGN expression
    | lvalue OP_DIV_ASSIGN expression
    | lvalue OP_MOD_ASSIGN expression
    ;

/* ---------------------- TIPOS E ARRAYS --------------------------------- */
type
    : base_type array_suffix_opt
    ;

base_type
    : TYPE_INTEGER
    | TYPE_REAL
    | TYPE_DECIMAL
    | TYPE_BOOLEAN
    | TYPE_CHAR
    | TYPE_STRING
    | TYPE_DATE
    | TYPE_TIME
    | TYPE_DICT
    | TYPE_SET
    | TYPE_VOID
    ;

array_suffix_opt
    : /* vazio */
    | L_BRACKET expression_opt R_BRACKET array_suffix_opt
    ;

expression_opt
    : expression
    | /* vazio */
    ;

/* ---------------------- CONTROLE DE FLUXO ------------------------------ */
if_stmt 
    : KEY_IF expression KEY_DO stmt %prec KEY_DO
    | KEY_IF expression KEY_DO stmt KEY_ELSE stmt
    ;

while_stmt 
    : KEY_WHILE expression KEY_DO stmt
    ;

for_stmt 
    : KEY_FOR ID KEY_IN expression KEY_DO stmt
    ;

/* ---------------------- FUNÇÕES ---------------------------------------- */
func_decl 
    : KEY_FUNCTION ID L_PAREN param_list_opt R_PAREN COLON base_type block
    ;

param_list_opt 
    : param_list
    | /* vazio */
    ;

param_list 
    : param_list COMMA param
    | param
    ;

param 
    : ID COLON type
    ;

func_call 
    : ID L_PAREN arg_list_opt R_PAREN
    ;

arg_list_opt 
    : arg_list
    | /* vazio */
    ;

arg_list 
    : arg_list COMMA expression
    | expression
    ;

/* ---------------------- EXPRESSÕES ------------------------------------- */
index_suffix_opt
    : /* vazio */
    | L_BRACKET expression R_BRACKET index_suffix_opt
    ;

expression 
    : expression OP_PLUS expression
    | expression OP_MINUS expression
    | expression OP_MULTIPLY expression
    | expression OP_DIVIDE expression
    | expression OP_INT_DIVIDE expression
    | expression OP_MOD expression
    | expression OP_EQ expression
    | expression OP_NE expression
    | expression OP_LT expression
    | expression OP_LE expression
    | expression OP_GT expression
    | expression OP_GE expression
    | expression OP_AND expression
    | expression OP_OR expression
    | OP_NOT expression
    | L_PAREN expression R_PAREN
    | literal
    | ID index_suffix_opt
    | func_call
    | FUNC_SIZE L_PAREN arg_list_opt R_PAREN
    | FUNC_SIZE L_PAREN type R_PAREN
    ;

/* Literais */
literal 
    : LIT_INT
    | LIT_REAL
    | LIT_STRING
    | LIT_NULL
    | KEY_TRUE
    | KEY_FALSE
    | L_BRACKET arg_list_opt R_BRACKET
    ;

%%

/* ========================================================================
   FUNÇÃO DE TRATAMENTO DE ERROS SINTÁTICOS
   Imprime a linha do erro, marca a coluna e incrementa o contador global.
   ======================================================================== */
void yyerror(const char *s) 
{
    extern int yylineno;
    extern char *yytext;
    extern YYLTYPE yylloc;

    fprintf(stderr,
        "\nErro sintatico: %s proximo de '%s' (linha %d, coluna %d)\n",
        s, yytext, yylloc.first_line, yylloc.first_column);

    fprintf(stderr, "%s\n", current_line);

    for (int i = 0; i < yylloc.first_column - 1; i++)
        fprintf(stderr, " ");
    fprintf(stderr, "^\n");

    syntax_errors++;
}

/* ========================================================================
   FUNÇÃO PRINCIPAL DO PROGRAMA
   Executa o parser e exibe o número total de erros sintáticos.
   ======================================================================== */
int main(void) 
{
    printf("Iniciando analise sintatica...\n");
    yyparse();

    if (syntax_errors == 0)
        printf("\nAnalise concluida sem erros.\n");
    else
        printf("\nAnalise concluida com %d erro(s) sintatico(s).\n", syntax_errors);

    return 0;
}
