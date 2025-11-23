# Compilador

compiler: lex.yy.c y.tab.c semantica.o
	gcc lex.yy.c y.tab.c semantica.o -o compiler

semantica.o: semantica.c semantica.h
	gcc -c semantica.c -o semantica.o

# Gerar o analisador léxico (scanner)
lex.yy.c: analisador.l
	flex analisador.l

# Gerar o parser (analisador sintático)
y.tab.c: parser.y
	bison -d -v parser.y -o y.tab.c

# Limpeza
clean:
	rm -rf lex.yy.c y.tab.* compiler output.txt y.output semantica.o