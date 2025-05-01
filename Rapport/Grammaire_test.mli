
(* The type of tokens. *)

type token = 
  | T
  | RPAR
  | LPAR
  | FUN
  | ARROW

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val expression: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (unit)
