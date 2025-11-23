#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "semantica.h"

Simbolo tabela[1000];
int qtSimbolos = 0;
 
void adicionarSimbolo(const char* nome, const char* tipo) { 
    for (int i = 0; i < qtSimbolos; i++) {
        if (strcmp(tabela[i].nome, nome) == 0) {
            char buf[256];
            snprintf(buf, sizeof(buf), "Variável '%s' já declarada anteriormente.", nome);
            erroSemantico(buf);
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

void erroSemantico(const char* msg, ...) {
    va_list args;
    va_start(args, msg);
    
    printf("Erro semântico: ");
    vprintf(msg, args);
    printf("\n");
    
    va_end(args);
    exit(1);
}