Require Import Ltac2.Ltac2.
Require Import Ltac2.Message.

Require Import Util.Constr.
Require Import Util.Goals.
Require Import Util.Hypothesis.

Ltac2 Type exn ::= [ TakeError(message) ].

Local Ltac2 too_many_of_type_message (t : constr) := 
  concat (concat (of_string "Tried to introduce too many variables of type ") (of_constr t)) (of_string ".").

Local Ltac2 expected_of_type_instead_of_message (e : constr) (t : constr) := 
  concat (concat 
    (concat (of_string "Expected variable of type ") (of_constr e))
    (concat (of_string " instead of ") (of_constr t))) (of_string ".").


(**
  Introduces a variable.

    Arguments:
        - [id : ident ]: variable to introduce.
        - [type: constr]: type of the variable [id].
    Does:
        - Introduces the variable [id].
    Raises Exceptions:
        - [TakeError], if the current goal does not require the introduction
          of a variable of type [type], including coercions of [type].
*)
Local Ltac2 intro_ident (id : ident) (type : constr) :=
  lazy_match! goal with
    | [ |- forall _ : ?u, _] =>
      let ct := get_coerced_type type in
      (* Check whether we need a variable of type [type], including coercions of [type]. *)
      match check_constr_equal u ct with
        | true  => intro $id
        | false => Control.zero (TakeError (too_many_of_type_message type))
      end
    | [ |- _] => Control.zero (TakeError (too_many_of_type_message type))
  end.


(**
  Introduces a list of variables of single type.

  Arguments:
    - [pair : (ident list * constr)]: list of variables paired with their type.

  Does:
    - Introduces the variables in [pair].
    
  Raises Exceptions:
    - [TakeError], if the current goal does not require the introduction of a variable of type [type], including coercions of [type].
*)
Local Ltac2 intro_per_type (pair : ident list * constr) :=
  let (ids, type) := pair in 
  lazy_match! goal with
    | [ |- forall _ : ?u, _] => 
      (* Check whether [u] is not a proposition. *)
      let sort_u := get_value_of_hyp u in
      match check_constr_equal sort_u constr:(Prop) with
        | false =>
          (* Check whether we need variables of type [type], including coercions of [type]. *)
          let ct := get_coerced_type type in
          match check_constr_equal u ct with
            | true  => List.iter (fun id => intro_ident id type) ids
            | false => Control.zero (TakeError (expected_of_type_instead_of_message u type))
          end
        | true  => Control.zero (TakeError (of_string "Tried to introduce too many variables."))
      end
    | [ |- _ ] => Control.zero (TakeError (of_string "Tried to introduce too many variables."))
  end.


(**
  Checks whether variables need to be introduced, attempts to introduce a list of variables of certain types.
*)
Local Ltac2 take (x : (ident list * constr) list) := 
  lazy_match! goal with
    | [ |- forall _ : ?u, _] => 
      (* Check whether [u] is not a proposition. *)
      let sort_u := get_value_of_hyp u in
      match check_constr_equal sort_u constr:(Prop) with
        | false => List.iter intro_per_type x
        | true  => Control.zero (TakeError (of_string "`Take ...` cannot be used to prove an implication (⇨). Use `Assume that ...` instead."))
      end
    | [ |- _ ] => Control.zero (TakeError (of_string "`Take ...` can only be used to prove a `for all`-statement (∀) or to construct a map (→)."))
  end.

Ltac2 Notation "Take" x(list1(seq(list1(ident, ","), ":", constr), "and")) := 
  panic_if_goal_wrapped ();
  take x.