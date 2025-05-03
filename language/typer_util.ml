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

let type_of_built_in (counter : Counter.t) (built_in : built_in) =
  match built_in with
  | Add -> TFunc ([], TInt, TFunc ([], TInt, TInt))
  | Sub -> TFunc ([], TInt, TFunc ([], TInt, TInt))
  | Mul -> TFunc ([], TInt, TFunc ([], TInt, TInt))
  | Div -> TFunc ([], TInt, TFunc ([], TInt, TInt))
  | Mod -> TFunc ([], TInt, TFunc ([], TInt, TInt))
  | And -> TFunc ([], TBool, TFunc ([], TBool, TBool))
  | Or -> TFunc ([], TBool, TFunc ([], TBool, TBool))
  | UMin -> TFunc ([], TInt, TInt)
  | Eq  -> let a = TUniv (Counter.get_fresh counter)
            in TFunc ([], a, TFunc ([], a, TBool))
  | Neq -> let a = TUniv (Counter.get_fresh counter)
            in TFunc ([], a, TFunc ([], a, TBool))
  | Lt  -> let a = TUniv (Counter.get_fresh counter)
            in TFunc ([], a, TFunc ([], a, TBool))
  | Gt  -> let a = TUniv (Counter.get_fresh counter)
            in TFunc ([], a, TFunc ([], a, TBool))
  | Leq -> let a = TUniv (Counter.get_fresh counter)
            in TFunc ([], a, TFunc ([], a, TBool))
  | Geq -> let a = TUniv (Counter.get_fresh counter)
            in TFunc ([], a, TFunc ([], a, TBool))
  | Head-> let a = TUniv (Counter.get_fresh counter)
            in TFunc ([], TList ([], a), a)
  | Tail-> let a = TUniv (Counter.get_fresh counter)
            in TFunc ([], TList ([], a), TList ([], a))
  | Not -> TFunc ([], TBool, TBool)
  | Concat -> let a = TUniv (Counter.get_fresh counter)
              in TFunc([], TList ([], a), TFunc ([], TList ([], a), TList ([], a)))
  | Cat    -> let a = TUniv (Counter.get_fresh counter)
              in TFunc([], TList ([], a), TFunc ([], TList ([], a), TList ([], a)))
  | Append -> let a = TUniv (Counter.get_fresh counter)
              in TFunc([], TList ([], a), TFunc ([], TList ([], a), TList ([], a)))
  | Print -> let a = TUniv (Counter.get_fresh counter)
              in TFunc ([], a, TUnit)

let instantiate counter t =
  let subst = Hashtbl.create 10 in
  let rec aux t =
    match t with
    | TUniv n when Hashtbl.mem subst n -> Hashtbl.find subst n
    | TUniv n ->
      let fresh = TUniv (Counter.get_fresh counter)
        in Hashtbl.add subst n fresh;
      fresh
    | TFunc (_, a, r) -> TFunc ([], aux a, aux r)
    | TList (_, t1) -> TList ([], aux t1)
    | _ -> t
  in aux t



let rec occurs n t =
  match t with
  | TUniv m -> m = n
  | TFunc (_, t1, t2) -> occurs n t1 || occurs n t2
  | TList (_, t1) -> occurs n t1
  | _ -> false

let rec solve_constraints constraints =
  match constraints with
  | [] -> []
  | (t1, t2) :: rest ->
    match (t1, t2) with
    | _ when t1 = t2 -> solve_constraints rest
    | TUniv n, t | t, TUniv n ->
      if occurs n t
        then raise (Constraint_error (TUniv n, t))
      else
        let subst = [(n, t)]
          in let rest' = List.map (fun (t1, t2) -> substitute_constraint n t (t1, t2)) rest
            in let s = solve_constraints rest'
              in subst @ s
    | TFunc (_, t1a, t1r), TFunc (_, t2a, t2r) -> solve_constraints ((t1a, t2a) :: (t1r, t2r) :: rest)
    | TList (_, t1'), TList (_, t2') -> solve_constraints ((t1', t2') :: rest)
    | _, _ -> raise (Constraint_error (t1, t2))