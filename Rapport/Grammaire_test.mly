%token FUN
%token T
%token ARROW
%token LPAR
%token RPAR

%start <unit> expression

%%

expression :
  expr { () }
;

expr :
| FUN T ARROW expr { () }
| expr expr { () }
| T { () }
| LPAR expr RPAR { () }
;