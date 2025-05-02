open Ast
open Typer_util

let rec string_of_type t =
  match t with
  | TInt -> "int"
  | TBool -> "bool"
  | TString -> "string"
  | TUnit -> "unit"
  | TList (_, t_elem) -> "list(" ^ string_of_type t_elem ^ ")"
  | TFunc (_, t1, t2) -> "(" ^ string_of_type t1 ^ " -> " ^ string_of_type t2 ^ ")"
  | TUniv id -> "'a" ^ string_of_int id

let rec type_expr (counter : Counter.t) (env : type_lang Util.Environment.t) (expr : expr) =
  match expr with
  | Cst_i (_, _) -> TInt,[]
  | Cst_b (_, _) -> TBool,[]
  | Cst_str (_, _) -> TString,[]
  | Cst_func (b, _) -> type_of_built_in counter b,[]
  | Binop (e1, e2, op, _) ->
    let t1, _ = type_expr counter env e1 in
    let t2, _ = type_expr counter env e2 in(
    match op with
    | Add ->
      if t1 = TInt && t2 = TInt
        then TInt,[]
      else
        failwith ("Opération non définie entre " ^ string_of_type t1 ^ " et " ^ string_of_type t2)
    | Sub ->
      if t1 = TInt && t2 = TInt
        then TInt,[]
      else
        failwith ("Opération non définie entre " ^ string_of_type t1 ^ " et " ^ string_of_type t2)
    | Mul ->
      if t1 = TInt && t2 = TInt
        then TInt,[]
      else
        failwith ("Opération non définie entre " ^ string_of_type t1 ^ " et " ^ string_of_type t2)
    | Div ->
      if t1 = TInt && t2 = TInt
        then TInt,[]
      else
        failwith ("Opération non définie entre " ^ string_of_type t1 ^ " et " ^ string_of_type t2)
    | Mod ->
      if t1 = TInt && t2 = TInt
        then TInt,[]
      else
        failwith ("Opération non définie entre " ^ string_of_type t1 ^ " et " ^ string_of_type t2)
    | Eq ->
      if t1 = t2
        then TBool,[]
      else
        failwith ("Comparaison entre types incompatibles " ^ string_of_type t1 ^ " et " ^ string_of_type t2)
    | Neq ->
      if t1 = t2
        then TBool,[]
      else
        failwith ("Comparaison entre types incompatibles " ^ string_of_type t1 ^ " et " ^ string_of_type t2)
    | Lt ->
      if t1 = t2
        then TBool,[]
      else
        failwith ("Comparaison entre types incompatibles " ^ string_of_type t1 ^ " et " ^ string_of_type t2)
    | Gt ->
      if t1 = t2
        then TBool,[]
      else
        failwith ("Comparaison entre types incompatibles " ^ string_of_type t1 ^ " et " ^ string_of_type t2)
    | Leq ->
      if t1 = t2
        then TBool,[]
      else
        failwith ("Comparaison entre types incompatibles " ^ string_of_type t1 ^ " et " ^ string_of_type t2)
    | Geq ->
      if t1 = t2
        then TBool,[]
      else
        failwith ("Comparaison entre types incompatibles " ^ string_of_type t1 ^ " et " ^ string_of_type t2)
    | _ -> failwith "Opérateur inconnu")
  | Nil _ -> TList ([], TInt),[]
  | Unit _ -> TUnit,[]
  | Var (x, _) ->(
    match Util.Environment.get env x with
    | Some t -> t,[]
    | None -> failwith ("Variable non définie: " ^ x)
  )
  | IfThenElse (e1, e2, e3, _) ->
    let t1, c1 = type_expr counter env e1 in
    let t2, c2 = type_expr counter env e2 in
    let t3, c3 = type_expr counter env e3 in
    if t1 = TBool && t2 = t3
      then t2, c1 @ c2 @ c3
    else
      failwith "Les types des branches de IfThenElse ne sont pas compatibles"
  | App (e1, e2, _) ->
    let t1, c1 = type_expr counter env e1 in
    let t2, c2 = type_expr counter env e2 in(
    match t1 with
    | TFunc (_, arg_type, return_type) ->
      if arg_type = t2
        then return_type, c1 @ c2
      else
        failwith "Argument de fonction de type incompatible"
    | _ -> failwith "Tentative d'appliquer une expression non fonctionnelle")
  | Let (_, x, e1, e2, _) ->
    let t1, c1 = type_expr counter env e1 in
    let new_env = Util.Environment.copy env in
    Util.Environment.add new_env x t1;
    let t2, c2 = type_expr counter new_env e2
      in t2, c1 @ c2
  | Fun (x, e, _) ->
    let arg_type = TUniv (Counter.get_fresh counter) in
    let new_env = Util.Environment.copy env in
    Util.Environment.add new_env x arg_type;
    let return_type, c = type_expr counter new_env e
      in TFunc ([], arg_type, return_type), c
  | Ignore (e1, e2, _) ->
    let _, c1 = type_expr counter env e1 in
    let t2, c2 = type_expr counter env e2
      in t2, c1 @ c2