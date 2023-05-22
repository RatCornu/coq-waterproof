Require Import Ltac2.Ltac2.

Require Import Util.Init.
Require Import Waterprove.

Ltac2 Type exn ::= [ AutomationFailure(string) ].

Local Ltac2 raise_automation_failure () :=
  Control.zero (AutomationFailure "Waterproof could not verify that this statement is enough to prove the goal.").

(**
  Execute a function [f] (assuming it contains an expression that applies the [enough ... by ...] tactic).
  
  If it succeeds, print that [statement] is sufficient to show the goal. Raise an error if [f] also does.

  Arguments:
    - [f: unit -> unit], expression applying the tactic [enough ... by ...].
    - [statement: constr], statement that was 'enough'  evidence to proof the goal. Only used for printing purposes.
    
  Raises exceptions:
    - [AutomationFailure], in case [f] throws an error.
      This typically happens if the [enough ... by ...]-expression fails to prove the goal.
*)
Local Ltac2 try_enough_expression (f: unit -> unit) (statement: constr) :=
  match Control.case f with
    | Val _ => ()
    | Err exn => raise_automation_failure ()
  end.

(**
  Try if the [waterprove] automation would be able to solve the current goal, if [statement] were to hold.
  
  If it succeeds, the goal is removed, and proving [statement] is added as a new goal. If it fails, an error will be raised.

  Arguments:
    - [statement: constr], statement to assume to hold (and to be proven later).
    - [proving_lemma: constr], lemma that can help in the proof
    
  Raises exceptions:
    - [AutomationFailure], in case [waterprove] fails to prove the goal, even if [statement] is given.
*)
Ltac2 apply_enough_with_waterprove (statement:constr) (proving_lemma: constr option) :=
  let help_lemma := unwrap_optional_lemma proving_lemma in
  let hyp_name := Fresh.in_goal @h in
  let f () := enough ($hyp_name : $statement) by (waterprove 5 true [fun () => help_lemma] Positive) in
  try_enough_expression f statement.

(**
  Same as the function [apply_enough_with_waterprove].

  Take [statement] as a given fact, and try to prove the current goal automatically with it.
    
  If it succeeds, the goal is removed, and proving [statement] is added as a new goal. If it fails, an error will be raised.

  Arguments:
    - [statement: constr], statement to assume to hold (and to be proven later).
    
  Raises exceptions:
    - [AutomationFailure], in case no proof is found for the goal, even if [statement] is given.
*)
Ltac2 Notation "It" "suffices" "to" "show" "that" statement(constr) := 
  apply_enough_with_waterprove statement None.

(**
  Same as "It suffices to show that" except it adds an additional lemma temporarily to the underlying automation.

  Arguments:
    - [statement: constr], statement to assume to hold (and to be proven later).
    - [lemma: constr], lemma that can help in the proof
    
  Raises exceptions:
    - [AutomationFailure], in case no proof is found for the goal, even if [statement] is given.
*)
Ltac2 Notation "By" lemma(constr) "it" "suffices" "to" "show" "that" statement(constr) :=
  apply_enough_with_waterprove statement (Some lemma).