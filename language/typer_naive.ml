open Ast
open Typer_util

let rec type_expr (counter : Counter.t) (env : type_lang Util.Environment.t)
    (expr : expr) =
  (* la suite est à modifier -- c’est juste là pour ne pas avoir de warning tant que vous ne travaillez pas dessus.*)
  match expr with
  | App (e, _, _) -> type_expr counter env e
  | _ -> failwith "weak typer not implemented"
