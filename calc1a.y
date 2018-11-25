%{
#include <stdio.h>
#include <ctype.h>
#include <math.h>

int yylex(void);
void yyerror(char *);

int level;
%}

%token NUMBER
%left '+' '-'
%left '*' '/'

%%

list:	/* empty */
	| list '\n'
	| list expr '\n'
	{
		printf(
			"\tpushl\t%%eax\n"
			"\tcalll\t_printf\n"
		);
		level = level + 4;
	}
	;

expr:	NUMBER	{
    		printf("\tpushl\t$%d\n", $1);
	}
	| expr '+' expr				{ $$ = $1 + $3; }
	| expr '-' expr				{ $$ = $1 - $3; }
	| expr '*' expr				{ $$ = $1 * $3; }
	| expr '/' expr				{ $$ = $1 / $3; }
	;

%%

int
yylex(void)
{
	int c;
	while ((c = getchar()) == ' ' || c == '\t')	/* skip white spaces */
		;
	if (c == EOF)					/* the $end */
		return 0;
	if (isdigit(c)) {			/* a number */
		ungetc(c, stdin);
		scanf("%d", &yylval);
		return NUMBER;
	}
	return c;
}

void
yyerror(char *s)
{
	fprintf(stderr, "%s\n", s);
}

int
main(void)
{
	level = 12;
	printf(
		"\t.section\t__TEXT,__text,regular,pure_instructions\n"
		"\t.globl\t_main\n"
		"_main:\n"
		"\tsubl\t$12, %%esp\n"
		"\tcalll\tL0$pb\n"
		"L0$pb:\n"
		"\tpopl\t%%eax\n"
		"\tsubl\t$8, %%esp\n"
		"\tleal\tL_.str-L0$pb(%%eax), %%eax\n"
	);
	yyparse();
	printf(
		"\taddl\t$%d, %%esp\n"
		"\txorl\t%%eax, %%eax\n"
		"\taddl\t$12, %%esp\n"
		"\tretl\n\n"
		"\t.section\t__TEXT,__cstring,cstring_literals\n"
		"L_.str:\n"
		"\t.asciz\t\"%%d\\n\"\n\n"
		".subsections_via_symbols\n",
		level
	);
	return 0;
}
