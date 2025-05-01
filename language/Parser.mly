%{
    open Ast
%}

%nonassoc IN ELSE ARROW
%nonassoc NOT NEG
%left MUL DIV MOD
%left ADD SUB
%right CAT APPEND
%left CONCAT
%left EQ NEQ LT GT LEQ GEQ
%left AND OR
%left SEMICOLON

%start <Ast.t> main

%%

main:
| l = req_list EOF { l }

req_list:
| r = req l = req_list { r::l }
| r = req { [r] }

id_list:
|                        { [] }
| x = ID                 { [x] }
| x = ID xs = id_list    { x :: xs }

req:
| LET name = ID args = id_list EQ e = expr {
    let body = List.fold_right (fun arg acc -> Fun(arg, acc, Annotation.create $loc)) args e in
    (false, name, body)
}
| LET REC name = ID args = id_list EQ e = expr {
    let body = List.fold_right (fun arg acc -> Fun(arg, acc, Annotation.create $loc)) args e in
    (true, name, body)
}

expr:
| e1 = expr op = binop e2 = expr { Binop(e1, e2, op, Annotation.create $loc) }
| e = simple_expr { e }
| IF test = expr THEN th = expr ELSE el = expr { IfThenElse(test,th,el,Annotation.create $loc) }
| LET x = ID EQ e1 = expr IN e2 = expr { Let(false,x, e1 ,e2,Annotation.create $loc) }
| LET REC x = ID EQ e1 = expr IN e2 = expr { Let(true,x, e1 ,e2,Annotation.create $loc) }
| FUN x = ID ARROW e = expr { Fun(x,e,Annotation.create $loc) }
| e1 = expr SEMICOLON e2 = expr { Ignore(e1,e2,Annotation.create $loc) }
| e1 = app_expr e2 = simple_expr { App(e1,e2,Annotation.create $loc) } 

simple_expr:
| SUB e = simple_expr { App(Cst_func(UMin, Annotation.create $loc), e, Annotation.create $loc) }
| i = INT { Cst_i(i,Annotation.create $loc) }
| b = BOOL { Cst_b(b,Annotation.create $loc) }
| s = STRING { Cst_str(s,Annotation.create $loc) }
| f = built_in { Cst_func(f,Annotation.create $loc) }
| L_PAR R_PAR { Unit(Annotation.create $loc)}
| l = list_literal { l }
| x = ID { Var(x,Annotation.create $loc) }
| L_PAR e = expr R_PAR { e }

list_literal:
| L_SQ R_SQ { Nil(Annotation.create $loc) }
| L_SQ hd = expr tl = list_tail R_SQ {
    List.fold_right (fun h t ->
      App(App(Cst_func(Cat, Annotation.create $loc), h, Annotation.create $loc), t, Annotation.create $loc)
    ) (hd :: tl) (Nil(Annotation.create $loc))
}

list_tail:
|                              { [] }
| SEMICOLON e = expr tl = list_tail { e :: tl }

app_expr:
| f = simple_expr { f }
| f = app_expr e = simple_expr { App(f,e,Annotation.create $loc)} 

%inline binop:
| ADD   { Add }
| SUB   { Sub }
| MUL   { Mul }
| DIV   { Div }
| MOD   { Mod }
| AND   { And }
| OR    { Or }
| EQ    { Eq }
| NEQ   { Neq }
| LT    { Lt }
| GT    { Gt }
| LEQ   { Leq }
| GEQ   { Geq }
| CONCAT { Concat }
| CAT   { Cat }
| APPEND { Append }

%inline built_in:
| L_PAR b = binop R_PAR { b }
| NEG   { UMin }
| NOT   { Not }
| HEAD  { Head }
| TAIL  { Tail }
| PRINT { Print }
