# Compilador

compiler: lex.yy.c y.tab.c
	gcc lex.yy.c y.tab.c -o compiler

# Gerar o analisador léxico (scanner)
lex.yy.c: analisador.l
	flex analisador.l

# Gerar o parser (analisador sintático)
y.tab.c: parser.y
	bison -d -v parser.y -o y.tab.c

# Limpeza
clean:
	rm -rf lex.yy.c y.tab.* compiler output.txt y.output
