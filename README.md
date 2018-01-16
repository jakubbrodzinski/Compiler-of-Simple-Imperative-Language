# Compiler
Projekt zawiera pliki:
        Plik zawierający parser, w którym została zawarta logika kompilatora.
	-bison.y
        Plik zawierający lexer.
	-flex.l
        Struktura danych, która ma za zadanie przechowywać wyjściowego assemblera.
	-commandArray.c
        Prosta struktura danych wykorzystywana do implementacji skoków (zapamietująca linijki w których skoki się znajdowały) w petląch i if-elsach.
	-jumpStack.c
        Struktura danych reprezentująca taśmę pamięci 'p', w której zapamietujemy nazwy zmiennych oraz ich adresy.
	-variableStack.c
	-interpreter.cc
	-interpreter-cln.cc
	-Makefile

Wersje:
	flex 2.6.0
	bison (GNU Bison) 3.0.4
	gcc (Ubuntu 5.4.0-6ubuntu1~16.04.5) 5.4.0 20160609

Uruchomienie:

	Aby zbudowac projekt możemy użyc polecenia 'make' lub też poleceń 'make compiler' (który buduje kompilator) oraz 'make interpreter' (które buduje interpreter).

	Aby program skompilować i uruchomic nalezy użyć polecenia:
		'make run SRC=path'
	lub dla interpretera CLN:
		'make runCLN SRC=path'
	gdzie 'path' to scieżka do pliku z kodem źródłowym.

	Wyjściowy assembler trafia zawsze to pliku o nazwie 'output'.

	Aby kod źródłowy jedynie skompilować (bez uruchomienia w interpreterze) należy użyc:
		'make compile SRC=path'

	Aby uruchomic assembler używamy (pamietając, że kod assemblerowy musi być w pliku o nazwie 'output' !):
		'make exc'
	lub
		'make excCLN'

	Polecenie 'make clean' czyści wszystkie wygenerowane pliki przez flexa/bisona/gcc/kompilator.
