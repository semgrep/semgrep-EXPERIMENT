open Ast_js

(* the hooks *)
type visitor_in = {
  kexpr : (expr -> unit) * visitor_out -> expr -> unit;
  kstmt : (stmt -> unit) * visitor_out -> stmt -> unit;
  ktop : (a_toplevel -> unit) * visitor_out -> a_toplevel -> unit;
  kprop : (property -> unit) * visitor_out -> property -> unit;
  kparam :
    (parameter_classic -> unit) * visitor_out -> parameter_classic -> unit;
  kinfo : (tok -> unit) * visitor_out -> tok -> unit;
}

and visitor_out = any -> unit

val default_visitor : visitor_in
val mk_visitor : visitor_in -> visitor_out

(* poor's man fold *)
val do_visit_with_ref : ('a list ref -> visitor_in) -> any -> 'a list
