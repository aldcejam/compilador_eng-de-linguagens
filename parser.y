%{
/* ======================= PROLOGO EM C =================================== */
/**
 * @brief Bloco de prólogo em C carregado literalmente no parser gerado.
 *
 * Aqui são incluídas bibliotecas C, protótipos de funções externa e
 * utilitários locais usados nas ações do parser.
 */

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "semantica.h"   /**< Módulo de semântica - adicionarSimbolo, obterTipo, erroSemantico */

int yylex(void);
void yyerror(const char *s);

/** @brief Linha atual do arquivo (preenchida pelo lexer para mensagens). */
extern char current_line[1024];
/** @brief Posição atual do cursor na linha (preenchida pelo lexer). */
extern int current_pos;

/** @brief Contador de erros sintáticos encontrados durante a análise. */
int syntax_errors = 0;

/**
 * @brief Verifica se dois tipos são compatíveis para atribuição.
 *
 * Regras simples implementadas:
 *  - Se forem iguais, são compatíveis.
 *  - int pode ser atribuído a real ou decimal (promoção implícita).
 *  - Outros casos retornam incompatível.
 *
 * @param left Tipo do lado esquerdo (destino).
 * @param right Tipo do lado direito (origem/expressão).
 * @return int 1 se compatíveis, 0 caso contrário.
 */
static int tiposCompativeisParaAtrib(const char *left, const char *right) {
    if (!left || !right) return 0;
    
    /* Se forem iguais, são compatíveis */
    if (strcmp(left, right) == 0) return 1;
    
    /* Se um for array, compara tipos base */
    char leftBase[64], rightBase[64];
    strcpy(leftBase, left);
    strcpy(rightBase, right);
    
    /* Remove dimensões de array */
    char *bracket = strchr(leftBase, '[');
    if (bracket) *bracket = '\0';
    
    bracket = strchr(rightBase, '[');
    if (bracket) *bracket = '\0';
    
    /* Compara tipos base */
    if (strcmp(leftBase, rightBase) == 0) return 1;
    
    /* Promoções numéricas */
    if ((strcmp(leftBase, "real") == 0 || strcmp(leftBase, "decimal") == 0) && 
        strcmp(rightBase, "int") == 0) return 1;
    
    return 0;
}

/**
 * @brief Retorna o tipo resultante de uma operação aritmética binária.
 *
 * Regras simplificadas:
 *  - se qualquer operando for decimal => resultado decimal
 *  - se qualquer operando for real => resultado real
 *  - se ambos forem int => int
 *  - senão => "error"
 *
 * A string retornada é alocada (strdup) e o chamador deve liberar.
 *
 * @param a Tipo do operando esquerdo.
 * @param b Tipo do operando direito.
 * @return char* String alocada com o tipo resultante.
 */
static char* tipoResultadoAritmetica(const char *a, const char *b) {
    if (!a || !b) return strdup("error");
    if (strcmp(a, "decimal") == 0 || strcmp(b, "decimal") == 0) return strdup("decimal");
    if (strcmp(a, "real") == 0 || strcmp(b, "real") == 0) return strdup("real");
    if (strcmp(a, "int") == 0 && strcmp(b, "int") == 0) return strdup("int");
    return strdup("error");
}
%}

/* ======================= DECLARAÇÕES DO BISON ============================ */

/**
 * @section Union
 * @brief Tipos de valor retornados por tokens e nonterminals.
 *
 * - sValue: usado para tokens que carregam texto (ID, literais).
 * - tipo: usado para nonterminals que propagam o tipo (strings alocadas).
 */
%union {
    char *sValue;   /* tokens: ID, literais (texto) */
    char *tipo;     /* tipos propagados entre nonterminals (strings alocadas com strdup) */
}

/* ======================= TOKENS (COM VALOR) ============================== */
/** @brief Identificador (nome de variável, função, etc.) */
%token <sValue> ID
/** @brief Literal inteiro (texto do token em sValue) */
%token <sValue> LIT_INT
/** @brief Literal real */
%token <sValue> LIT_REAL
/** @brief Literal string */
%token <sValue> LIT_STRING

/* ======================= TOKENS (SEM VALOR) ============================== */
%token LIT_NULL
%token KEY_TRUE KEY_FALSE

/* Palavras-chave e símbolos da linguagem (documentados) */
%token KEY_BEGIN KEY_END KEY_IF KEY_DO KEY_ELSE KEY_WHILE KEY_FOR KEY_IN
%token KEY_FUNCTION KEY_RETURN KEY_CONST KEY_BREAK KEY_CONTINUE KEY_EXIT

/* ======================= TIPOS PRIMITIVOS ================================ */
/**
 * @brief Tokens que representam nomes de tipos na linguagem.
 * Exemplos: TYPE_INTEGER -> "int", TYPE_REAL -> "real", etc.
 */
%token TYPE_INTEGER TYPE_REAL TYPE_DECIMAL TYPE_BOOLEAN TYPE_CHAR TYPE_STRING 
%token TYPE_DATE TYPE_TIME TYPE_DICT TYPE_SET TYPE_VOID

/* ======================= OPERADORES ===================================== */
/* Atribuições compostas */
%token OP_ASSIGN OP_PLUS_ASSIGN OP_MINUS_ASSIGN OP_MUL_ASSIGN OP_DIV_ASSIGN OP_MOD_ASSIGN 

/* Comparações */
%token OP_EQ OP_NE OP_LE OP_GE OP_LT OP_GT 

/* Aritméticos */
%token OP_PLUS OP_MINUS OP_MULTIPLY OP_INT_DIVIDE OP_DIVIDE OP_MOD OP_RANGE 

/* Lógicos */
%token OP_AND OP_OR OP_NOT 

/* Símbolos e pontuação */
%token L_PAREN R_PAREN L_BRACKET R_BRACKET L_BRACE R_BRACE 
%token COLON SEMICOLON COMMA DOT 

/* Funções e utilitários embutidos */
%token FUNC_STEP_BY
%token FUNC_INPUT FUNC_OUTPUT FUNC_OUTPUTLN

/* Exceções, tipos customizados, IO */
%token KEY_RAISE KEY_TRY KEY_EXCEPT KEY_FINALLY KEY_EXCEPTION
%token KEY_TYPE KEY_RECORD
%token FUNC_ALLOCATE FUNC_FREE FUNC_SIZE FUNC_READ FUNC_WRITE FUNC_APPEND FUNC_CLOSE

/* ======================= DECLARAÇÕES DE TIPO PARA NÃO-TERMINAIS ========== */
%type <sValue> lvalue
%type <tipo> type base_type expression literal var_decl
%type <tipo> array_suffix_opt stmt_or_decl_list stmt_or_decl
%type <tipo> assign_stmt if_stmt while_stmt for_stmt
%type <tipo> block func_decl param_list_opt param_list param
%type <tipo> func_call arg_list_opt arg_list array_elements

/* Não-terminais que não retornam tipo (usam void) */
%type <sValue> expr_list io_stmt

/* Adicionar token KEY_THEN que estava faltando */
%token KEY_THEN

/* ========================================================================
   PRECEDÊNCIA E ASSOCIATIVIDADE DOS OPERADORES
   Mantém a precedência matemática e lógica correta para parsing.
   ======================================================================== */
%left OP_OR
%left OP_AND
%left OP_EQ OP_NE OP_LT OP_LE OP_GT OP_GE
%left OP_PLUS OP_MINUS
%left OP_MULTIPLY OP_DIVIDE OP_INT_DIVIDE OP_MOD
%right OP_NOT
%right COLON

/* Resolução do "dangling else" */
%nonassoc KEY_THEN
%nonassoc KEY_ELSE

/* Permite rastrear linha e coluna nas mensagens de erro (YYLTYPE) */
%locations

/* Define o símbolo inicial */
%start prog

%%

/* ============================================================================
   REGRAS DA GRAMÁTICA
   Cada regra possui comentários Doxygen para documentação automática.
   ======================================================================== */

/* ---------------------- PROGRAMA PRINCIPAL ------------------------------ */
/**
 * @brief Ponto de entrada: programa é uma lista de statements.
 */
prog 
    : stmt_list
    ;

/**
 * @brief Lista encadeada de statements.
 */
stmt_list 
    : stmt_list stmt
    | stmt
    ;

/* ---------------------- STATEMENTS GERAIS ------------------------------- */
/**
 * @brief Statements possíveis no nível superior e em blocos.
 *
 * Inclui atribuições, controle de fluxo, chamadas de função, I/O e blocos.
 */
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
    | KEY_RETURN expression SEMICOLON { free($2); }
    | KEY_RETURN SEMICOLON
    | KEY_EXIT SEMICOLON
    | error SEMICOLON
    ;

/* ---------------------- ENTRADA E SAÍDA -------------------------------- */
/**
 * @brief Regras para operações de I/O.
 *
 * - FUNC_INPUT '(' ID ')' : lê valor e armazena em ID (verifica existência).
 * - FUNC_OUTPUT '(' expr_list ')' : imprime expressões (sem checagem de tipo aqui).
 */
io_stmt
    : FUNC_INPUT '(' ID ')' {
        /* input lê para a variável; verificar se existe */
        const char* t = obterTipo($3);
        if (!t) erroSemantico("Variável '%s' usada em input não declarada.", $3);
        free($3);
        $$ = NULL;
    }
    | FUNC_OUTPUT '(' expr_list ')' { 
        /* saída */ 
        $$ = NULL;
    }
    ;

/**
 * @brief Lista de expressões (argumentos de saída, etc.).
 */
expr_list
    : expression { 
        free($1);
        $$ = NULL;
    }
    | expr_list ',' expression { 
        free($3); 
        $$ = NULL;
    }
    ;

/* ---------------------- BLOCOS BEGIN ... END --------------------------- */
/**
 * @brief Bloco de comandos delimitado por KEY_BEGIN ... KEY_END.
 * @details Blocks podem conter declarações e statements misturados.
 */
block 
    : KEY_BEGIN stmt_or_decl_list KEY_END { $$ = $2; }
    ;

stmt_or_decl_list
    : stmt_or_decl_list stmt_or_decl { free($1); free($2); $$ = NULL; }
    | stmt_or_decl { free($1); $$ = NULL; }
    ;

stmt_or_decl
    : stmt { $$ = NULL; }
    | var_decl SEMICOLON { free($1); $$ = NULL; }
    ;

/* ---------------------- DECLARAÇÕES DE VARIÁVEIS ----------------------- */
/**
 * @brief Declaração de variáveis com checagem semântica básica.
 *
 * Formatos aceitos:
 *  - ID : type
 *  - ID : type := expression
 *  - const ID : type := expression
 *
 * Em declarações com inicialização, valida-se compatibilidade de tipos.
 */
var_decl 
    : ID COLON type {
        /* adiciona símbolo */
        if (obterTipo($1)) {
            char buf[256];
            snprintf(buf, sizeof(buf), "Variável '%s' já declarada.", $1);
            erroSemantico(buf);
        }
        adicionarSimbolo($1, $3);
        free($1);
        free($3);
        $$ = NULL;
    }
    | ID COLON type OP_ASSIGN expression {
        if (obterTipo($1)) {
            char buf[256];
            snprintf(buf, sizeof(buf), "Variável '%s' já declarada.", $1);
            erroSemantico(buf);
        }
        /* comparar tipo declarado ($3) com tipo da expressão ($5) */
        if (!tiposCompativeisParaAtrib($3, $5)) {
            char buf[256];
            snprintf(buf, sizeof(buf), "Atribuição inválida: tentando atribuir '%s' a '%s' na variável '%s'.", $5, $3, $1);
            erroSemantico(buf);
        }
        adicionarSimbolo($1, $3);
        free($1); free($3); free($5);
        $$ = NULL;
    }
    | ID COLON type OP_ASSIGN L_BRACKET array_elements R_BRACKET {  /* Array com inicialização */
        if (obterTipo($1)) {
            char buf[256];
            snprintf(buf, sizeof(buf), "Variável '%s' já declarada.", $1);
            erroSemantico(buf);
        }
        adicionarSimbolo($1, $3);
        free($1); free($3);
        free($6);
        $$ = NULL;
    }
    ;

/* ---------------------- LVALUE E INDEXAÇÃO DE ARRAYS -------------------- */
/**
 * @brief Definição de lvalue (variável simples ou indexada).
 */
lvalue
    : ID { $$ = $1; }
    | ID L_BRACKET expression R_BRACKET {
        /* Verifica se o índice é inteiro */
        if (strcmp($3, "int") != 0) {
            erroSemantico("Índice do array deve ser do tipo int, encontrado: %s", $3);
        }
        free($3);
        $$ = $1;
    }
    | ID L_BRACKET expression R_BRACKET L_BRACKET expression R_BRACKET {
        /* Indexação múltipla (matriz) */
        if (strcmp($3, "int") != 0 || strcmp($6, "int") != 0) {
            erroSemantico("Índices do array devem ser do tipo int");
        }
        free($3); free($6);
        $$ = $1;
    }
    ;

/**
 * @brief Regras de atribuição com verificação de tipos.
 */
assign_stmt 
    : lvalue OP_ASSIGN expression {
        /* obtém tipo da variável (à esquerda) */
        const char *leftName = $1;
        const char *leftType = obterTipo(leftName);
        if (!leftType) {
            char buf[256];
            snprintf(buf, sizeof(buf), "Lvalue '%s' não declarado na atribuição.", leftName);
            erroSemantico(buf);
        }
        
        /* Se for array, remove a parte dos colchetes para comparação */
        char *baseType = strdup(leftType);
        char *bracket = strchr(baseType, '[');
        if (bracket) *bracket = '\0';
        
        const char *rightType = $3;
        
        if (!tiposCompativeisParaAtrib(baseType, rightType)) {
            char buf[256];
            snprintf(buf, sizeof(buf), 
                    "Tipo incompatível na atribuição: esquerda='%s' direita='%s' (variável '%s').", 
                    baseType, rightType, leftName);
            erroSemantico(buf);
        }
        
        free(baseType);
        free((char*)leftName);
        free((char*)rightType);
        $$ = NULL;
    }
    | lvalue OP_PLUS_ASSIGN expression {
        /* requer tipos numéricos e compatibilidade similar */
        const char *leftName = $1;
        const char *lt = obterTipo(leftName);
        if (!lt) { 
            char buf[128]; 
            snprintf(buf, sizeof(buf),"Variável '%s' não declarada.", leftName); 
            erroSemantico(buf); 
        }
        
        /* Se for array, pega o tipo base */
        char *baseType = strdup(lt);
        char *bracket = strchr(baseType, '[');
        if (bracket) *bracket = '\0';
        
        if (!(strcmp(baseType,"int")==0 || strcmp(baseType,"real")==0 || strcmp(baseType,"decimal")==0)) {
            erroSemantico("Operador '+=' requer operando esquerdo numérico.");
        }
        const char *rt = $3;
        if (!(strcmp(rt,"int")==0 || strcmp(rt,"real")==0 || strcmp(rt,"decimal")==0)) {
            erroSemantico("Operador '+=' requer operando direito numérico.");
        }
        if (!tiposCompativeisParaAtrib(baseType, rt)) {
            erroSemantico("Operador '+=': tipo direito não pode ser atribuído ao tipo da esquerda.");
        }
        
        free(baseType);
        free((char*)leftName); 
        free((char*)rt);
        $$ = NULL;
    }
    ;

/* ---------------------- TIPOS E ARRAYS --------------------------------- */
/**
 * @brief Tipo = base_type + sufixo de array opcional.
 */
type
    : base_type array_suffix_opt {
        /* Combina tipo base com sufixo de array */
        if ($2) {
            char *result = malloc(strlen($1) + strlen($2) + 1);
            strcpy(result, $1);
            strcat(result, $2);
            free($1);
            free($2);
            $$ = result;
        } else {
            $$ = $1;
        }
    }
    ;


/**
 * @brief Sufixo de array opcional.
 */
array_suffix_opt
    : /* vazio */ { $$ = NULL; }
    | L_BRACKET R_BRACKET { $$ = strdup("[]"); }
    | L_BRACKET expression R_BRACKET { 
        /* Array com tamanho fixo - verificar se é int */
        if (strcmp($2, "int") != 0) {
            erroSemantico("Tamanho do array deve ser inteiro, encontrado: %s", $2);
        }
        free($2);
        $$ = strdup("[]"); 
    }
    ;

/**
 * @brief Base dos tipos (mapeia tokens para strings de tipo).
 * @return string alocada via strdup, que deve ser liberada pelo caller.
 */
base_type
    : TYPE_INTEGER { $$ = strdup("int"); }
    | TYPE_REAL    { $$ = strdup("real"); }
    | TYPE_DECIMAL { $$ = strdup("decimal"); }
    | TYPE_BOOLEAN { $$ = strdup("boolean"); }
    | TYPE_CHAR    { $$ = strdup("char"); }
    | TYPE_STRING  { $$ = strdup("string"); }
    | TYPE_DATE    { $$ = strdup("date"); }
    | TYPE_TIME    { $$ = strdup("time"); }
    | TYPE_DICT    { $$ = strdup("dict"); }
    | TYPE_SET     { $$ = strdup("set"); }
    | TYPE_VOID    { $$ = strdup("void"); }
    ;

/* ---------------------- CONTROLE DE FLUXO ------------------------------ */
/**
 * @brief If statement: KEY_IF expression KEY_THEN stmt [KEY_ELSE stmt]
 *
 * Libera o tipo da expressão após verificação.
 */
if_stmt 
    : KEY_IF expression KEY_THEN stmt {
        if (strcmp($2, "boolean") != 0) {
            erroSemantico("Condição do if deve ser booleana, encontrado: %s", $2);
        }
        free($2);
        $$ = NULL;
    }
    | KEY_IF expression KEY_THEN stmt KEY_ELSE stmt {
        if (strcmp($2, "boolean") != 0) {
            erroSemantico("Condição do if deve ser booleana, encontrado: %s", $2);
        }
        free($2);
        $$ = NULL;
    }
    ;

/**
 * @brief While statement: libera tipo da condição.
 */
while_stmt 
    : KEY_WHILE expression KEY_DO stmt {
        free($2);
        $$ = NULL;
    }
    ;

/**
 * @brief For statement (exemplo): verifica se variável de controle existe.
 */
for_stmt 
    : KEY_FOR ID KEY_IN expression KEY_DO stmt {
        /* o ID deve existir e a expressão deve ser iterável (não verificado aqui) */
        if (!obterTipo($2)) {
            erroSemantico("Variável de controle '%s' não declarada no for.", $2);
        }
        free($2);
        free($4);
        $$ = NULL;
    }
    ;

/* ---------------------- FUNÇÕES (esqueleto) ----------------------------- */
/**
 * @brief Declaração de função (esqueleto).
 *
 * Observação: tabela de funções e verificação de assinaturas não implementadas.
 */
func_decl 
    : KEY_FUNCTION ID L_PAREN param_list_opt R_PAREN COLON base_type block {
        /* declaração de função: não implementamos tabela de funções aqui */
        free($2);
        free($7);
        $$ = NULL;
    }
    ;

param_list_opt 
    : param_list { $$ = $1; }
    | /* vazio */ { $$ = NULL; }
    ;

param_list 
    : param_list COMMA param { free($1); free($3); $$ = NULL; }
    | param { free($1); $$ = NULL; }
    ;

param 
    : ID COLON type {
        /* parametros: ADICIONAR na tabela de símbolos */
        if (obterTipo($1)) {
            char buf[256];
            snprintf(buf, sizeof(buf), "Parâmetro '%s' já declarado.", $1);
            erroSemantico(buf);
        }
        adicionarSimbolo($1, $3);
        free($1); free($3);
        $$ = NULL;
    }
    ;

/**
 * @brief chamada de função (sem checagem de assinatura aqui).
 */
func_call 
    : ID L_PAREN arg_list_opt R_PAREN {
        free($1);
        $$ = strdup("unknown");
    }
    ;

arg_list_opt 
    : arg_list { free($1); $$ = NULL; }
    | /* vazio */ { $$ = NULL; }
    ;

arg_list 
    : arg_list COMMA expression { free($1); free($3); $$ = NULL; }
    | expression { $$ = $1; }
    ;

/* ---------------------- EXPRESSÕES ------------------------------------- */
/**
 * @brief Regras de expressão com verificação de tipo para cada operador.
 *
 * - Propaga tipos (strings alocadas) via $$.
 * - Libera as strings intermediárias para evitar leaks.
 * - Em caso de erro semântico chama erroSemantico com mensagem em português.
 */
expression 
    : expression OP_PLUS expression {
        if (!(strcmp($1,"int")==0 || strcmp($1,"real")==0 || strcmp($1,"decimal")==0) ||
            !(strcmp($3,"int")==0 || strcmp($3,"real")==0 || strcmp($3,"decimal")==0)) {
            char buf[256];
            snprintf(buf,sizeof(buf),"Operador '+' requer operandos numéricos: recebidos '%s' e '%s'.", $1, $3);
            erroSemantico(buf);
        }
        $$ = tipoResultadoAritmetica($1, $3);
        free($1); free($3);
    }
    | expression OP_MINUS expression {
        if (!(strcmp($1,"int")==0 || strcmp($1,"real")==0 || strcmp($1,"decimal")==0) ||
            !(strcmp($3,"int")==0 || strcmp($3,"real")==0 || strcmp($3,"decimal")==0)) {
            erroSemantico("Operador '-' requer operandos numéricos.");
        }
        $$ = tipoResultadoAritmetica($1, $3);
        free($1); free($3);
    }
    | expression OP_MULTIPLY expression {
        if (!(strcmp($1,"int")==0 || strcmp($1,"real")==0 || strcmp($1,"decimal")==0) ||
            !(strcmp($3,"int")==0 || strcmp($3,"real")==0 || strcmp($3,"decimal")==0)) {
            erroSemantico("Operador '*' requer operandos numéricos.");
        }
        $$ = tipoResultadoAritmetica($1, $3);
        free($1); free($3);
    }
    | expression OP_DIVIDE expression {
        if (!(strcmp($1,"int")==0 || strcmp($1,"real")==0 || strcmp($1,"decimal")==0) ||
            !(strcmp($3,"int")==0 || strcmp($3,"real")==0 || strcmp($3,"decimal")==0)) {
            erroSemantico("Operador '/' requer operandos numéricos.");
        }
        /* divisão retorna real/decimal */
        if (strcmp($1,"decimal")==0 || strcmp($3,"decimal")==0) $$ = strdup("decimal");
        else $$ = strdup("real");
        free($1); free($3);
    }
    | expression OP_INT_DIVIDE expression {
        if (!(strcmp($1,"int")==0 && strcmp($3,"int")==0)) {
            char buf[256];
            snprintf(buf, sizeof(buf), "Operador 'div' requer operandos inteiros: recebidos '%s' e '%s'", $1, $3);
            erroSemantico(buf);
        }
        $$ = strdup("int");
        free($1); free($3);
    }
    | expression OP_MOD expression {
        if (!(strcmp($1,"int")==0 && strcmp($3,"int")==0)) {
            char buf[256];
            snprintf(buf, sizeof(buf), "Operador 'mod' requer operandos inteiros: recebidos '%s' e '%s'", $1, $3);
            erroSemantico(buf);
        }
        $$ = strdup("int");
        free($1); free($3);
    }
    /* comparações -> boolean */
    | expression OP_EQ expression {
        /* permitimos igualdade entre mesmo tipo ou entre numéricos */
        if (strcmp($1,$3) != 0 && !(
            (strcmp($1,"int")==0 || strcmp($1,"real")==0 || strcmp($1,"decimal")==0) &&
            (strcmp($3,"int")==0 || strcmp($3,"real")==0 || strcmp($3,"decimal")==0)
        )) {
            char buf[256];
            snprintf(buf, sizeof(buf), "Operador '==' entre tipos incompatíveis: '%s' e '%s'", $1, $3);
            erroSemantico(buf);
        }
        $$ = strdup("boolean");
        free($1); free($3);
    }
    | expression OP_NE expression {
        if (strcmp($1,$3) != 0 && !(
            (strcmp($1,"int")==0 || strcmp($1,"real")==0 || strcmp($1,"decimal")==0) &&
            (strcmp($3,"int")==0 || strcmp($3,"real")==0 || strcmp($3,"decimal")==0)
        )) {
            char buf[256];
            snprintf(buf, sizeof(buf), "Operador '<>' entre tipos incompatíveis: '%s' e '%s'", $1, $3);
            erroSemantico(buf);
        }
        $$ = strdup("boolean");
        free($1); free($3);
    }
    | expression OP_LT expression
    | expression OP_LE expression
    | expression OP_GT expression
    | expression OP_GE expression {
        if (!(
            (strcmp($1,"int")==0 || strcmp($1,"real")==0 || strcmp($1,"decimal")==0) &&
            (strcmp($3,"int")==0 || strcmp($3,"real")==0 || strcmp($3,"decimal")==0)
        )) {
            char buf[256];
            snprintf(buf, sizeof(buf), "Operador relacional requer operandos numéricos: recebidos '%s' e '%s'", $1, $3);
            erroSemantico(buf);
        }
        $$ = strdup("boolean");
        free($1); free($3);
    }
    /* lógicos */
    | expression OP_AND expression {
        if (!(strcmp($1,"boolean")==0 && strcmp($3,"boolean")==0)) {
            char buf[256];
            snprintf(buf, sizeof(buf), "Operador 'and' requer operandos booleanos: recebidos '%s' e '%s'", $1, $3);
            erroSemantico(buf);
        }
        $$ = strdup("boolean");
        free($1); free($3);
    }
    | expression OP_OR expression {
        if (!(strcmp($1,"boolean")==0 && strcmp($3,"boolean")==0)) {
            char buf[256];
            snprintf(buf, sizeof(buf), "Operador 'or' requer operandos booleanos: recebidos '%s' e '%s'", $1, $3);
            erroSemantico(buf);
        }
        $$ = strdup("boolean");
        free($1); free($3);
    }
    | OP_NOT expression {
        if (!(strcmp($2,"boolean")==0)) {
            char buf[256];
            snprintf(buf, sizeof(buf), "Operador 'not' requer um operando booleano: recebido '%s'", $2);
            erroSemantico(buf);
        }
        $$ = strdup("boolean");
        free($2);
    }
    | L_PAREN expression R_PAREN { $$ = $2; }
    | literal { $$ = $1; }
    | ID {
        const char *t = obterTipo($1);
        if (!t) {
            char buf[128];
            snprintf(buf,sizeof(buf),"Identificador '%s' não declarado.", $1);
            erroSemantico(buf);
        }
        $$ = strdup(t);
        free($1);
    }
    | ID L_BRACKET expression R_BRACKET {
        /* Acesso a array indexado */
        const char *t = obterTipo($1);
        if (!t) {
            char buf[128];
            snprintf(buf,sizeof(buf),"Identificador '%s' não declarado.", $1);
            erroSemantico(buf);
        }
        
        /* Verifica se é um array */
        if (strstr(t, "[") == NULL) {
            erroSemantico("Tentativa de indexar variável não-array '%s' do tipo '%s'", $1, t);
        }
        
        /* Remove uma dimensão do array */
        char *resultType = strdup(t);
        char *bracket = strchr(resultType, '[');
        if (bracket) {
            char *secondBracket = strchr(bracket + 1, '[');
            if (secondBracket) {
                /* Array multidimensional - remove uma dimensão */
                *bracket = '\0';
                strcat(resultType, secondBracket);
            } else {
                /* Array unidimensional - vira tipo base */
                *bracket = '\0';
            }
        }
        
        /* Verifica se o índice é inteiro */
        if (strcmp($3, "int") != 0) {
            erroSemantico("Índice do array deve ser do tipo int, encontrado: %s", $3);
        }
        free($3);
        
        $$ = resultType;
        free($1);
    }
    | func_call { $$ = $1; } /* retorno desconhecido sem tabela de funções */
    | FUNC_SIZE L_PAREN arg_list_opt R_PAREN { free($3); $$ = strdup("int"); }
    | FUNC_SIZE L_PAREN type R_PAREN { free($3); $$ = strdup("int"); }
    ;

/**
 * @brief Literais da linguagem: cada literal devolve seu tipo.
 */
literal 
    : LIT_INT    { $$ = strdup("int"); free($1); }
    | LIT_REAL   { $$ = strdup("real"); free($1); }
    | LIT_STRING { $$ = strdup("string"); free($1); }
    | LIT_NULL   { $$ = strdup("null"); }
    | KEY_TRUE   { $$ = strdup("boolean"); }
    | KEY_FALSE  { $$ = strdup("boolean"); }
    | L_BRACKET array_elements R_BRACKET { free($2); $$ = strdup("int[]"); }  /* Array literal */
    ;

/**
 * @brief Elementos de array.
 */
array_elements
    : expression { $$ = $1; }
    | array_elements COMMA expression { free($1); free($3); $$ = NULL; }
    ;

%%

/* ======================= TRAITEMENTO DE ERROS SINTÁTICOS ======================= */
/**
 * @brief Função chamada pelo Bison quando ocorre erro sintático.
 *
 * Imprime uma mensagem detalhada com o trecho de código, linha e coluna.
 *
 * @param s Mensagem padrão do Bison.
 */
void yyerror(const char *s) 
{
    extern int yylineno;
    extern char *yytext;
    extern YYLTYPE yylloc;

    fprintf(stderr,
        "\nErro sintático: %s próximo de '%s' (linha %d, coluna %d)\n",
        s, yytext, yylloc.first_line, yylloc.first_column);

    fprintf(stderr, "%s\n", current_line);
    for (int i = 0; i < yylloc.first_column - 1; i++) fprintf(stderr, " ");
    fprintf(stderr, "^\n");

    syntax_errors++;
}

/* ======================= FUNÇÃO PRINCIPAL (MAIN) ======================= */
/**
 * @brief Ponto de entrada para teste do parser.
 *
 * Executa yyparse() e reporta o número de erros sintáticos.
 */
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