#ifndef SEMANTICA_H
#define SEMANTICA_H

// Estrutura de um símbolo na tabela
typedef struct {
    char nome[100];   // nome da variável
    char tipo[20];    // tipo (int, string, bool...)
} Simbolo;

// Tabela de símbolos
extern Simbolo tabela[1000];
extern int qtSimbolos;

// Funções públicas
void adicionarSimbolo(const char* nome, const char* tipo);
const char* obterTipo(const char* nome);
void erroSemantico(const char* msg);

#endif
