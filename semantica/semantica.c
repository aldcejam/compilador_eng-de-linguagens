#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "semantica.h"

Simbolo tabela[1000];
int qtSimbolos = 0;
 
void adicionarSimbolo(const char* nome, const char* tipo) { 
    for (int i = 0; i < qtSimbolos; i++) {
        if (strcmp(tabela[i].nome, nome) == 0) {
            erroSemantico("Variável já declarada anteriormente.");
        }
    }

    strcpy(tabela[qtSimbolos].nome, nome);
    strcpy(tabela[qtSimbolos].tipo, tipo);
    qtSimbolos++;
}
 
const char* obterTipo(const char* nome) {
    for (int i = 0; i < qtSimbolos; i++) {
        if (strcmp(tabela[i].nome, nome) == 0)
            return tabela[i].tipo;
    }
    return NULL;
} 

void erroSemantico(const char* msg) {
    printf("Erro semântico: %s\n", msg);
    exit(1);
}
