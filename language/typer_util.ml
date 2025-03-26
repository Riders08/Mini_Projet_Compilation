open Type_system
open Ast

exception Constraint_error of type_lang * type_lang
exception Typing_error of Util.Position.t * string

module Counter = struct
  type t = int ref

  let create () = ref 0

  let get_fresh counter =
    let res = !counter in
    counter := !counter + 1;
    res
end

let type_of_built_in (built_in : built_in) =
  match built_in with
  | Add -> TFunc ([], TInt, TFunc ([], TInt, TInt))
  (* à modifier après ça*)
  | _ -> failwith "built_in not yet typed"

let rec solve_constraints (constraints : (type_lang * type_lang) list) :
    (int * type_lang) list =
  match constraints with
  (* à modifier après ça*)
  | [] -> failwith "solve_constraints not implemented"
  | ((TFunc _ as f), TBool) :: _ -> raise (Constraint_error (f, TBool))
  | _ :: t ->
      ignore substitute_constraint;
      solve_constraints t

let instantiate (counter : Counter.t) (type_lang : type_lang) : type_lang =
  (* à modifier*)
  let _ = Counter.get_fresh counter in
  match type_lang with _ -> type_lang
