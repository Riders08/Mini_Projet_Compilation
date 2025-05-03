open Ast
open Typer_util

let rec type_expr (counter : Counter.t) (env : type_lang Util.Environment.t) (expr : expr) : type_lang * (type_lang * type_lang) list =
  match expr with
  | Cst_i _ -> TInt, []
  | Cst_b _ -> TBool, []
  | Cst_str _ -> TString, []
  | Cst_func (b, _) -> let t = type_of_built_in counter b
                        in t, []
  | Unit _ -> TUnit, []
  | Nil _ -> let fresh = TUniv (Counter.get_fresh counter)
              in TList ([], fresh), []
  | Var (x, pos) -> (
    match Util.Environment.get env x with
    | Some t -> t, []
    | None -> raise (Typing_error (Annotation.get_pos pos, "Variable non définie: " ^ x))
  )
  | Binop (e1, e2, op, _) ->
    let t1, c1 = type_expr counter env e1
      in let t2, c2 = type_expr counter env e2
        in let res_type = TUniv (Counter.get_fresh counter)
          in let op_type = type_of_built_in counter op
            in let app_type = TFunc ([], t1, TFunc ([], t2, res_type))
              in let constraints = (op_type, app_type) :: c1 @ c2
                in res_type, constraints
  | IfThenElse (e1, e2, e3, _) ->
    let t1, c1 = type_expr counter env e1
      in let t2, c2 = type_expr counter env e2
        in let t3, c3 = type_expr counter env e3
          in let constraints = (t1, TBool) :: (t2, t3) :: c1 @ c2 @ c3
            in t2, constraints
  | App (e1, e2, _) ->
      let t1, c1 = type_expr counter env e1
        in let t2, c2 = type_expr counter env e2
          in let res = TUniv (Counter.get_fresh counter)
            in let constraints = (t1, TFunc ([], t2, res)) :: c1 @ c2
              in res, constraints
  | Let (_, x, e1, e2, _) ->
    let t1, c1 = type_expr counter env e1
      in let env' = Util.Environment.copy env
        in Util.Environment.add env' x t1;
    let t2, c2 = type_expr counter env' e2
      in t2, c1 @ c2
  | Fun (x, e, _) ->
    let arg_type = TUniv (Counter.get_fresh counter)
      in let env' = Util.Environment.copy env
        in Util.Environment.add env' x arg_type;
    let return_type, c = type_expr counter env' e
      in TFunc ([], arg_type, return_type), c
  | Ignore (e1, e2, _) ->
    let _, c1 = type_expr counter env e1
      in let t2, c2 = type_expr counter env e2
        in t2, c1 @ c2