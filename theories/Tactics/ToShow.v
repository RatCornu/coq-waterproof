(******************************************************************************)
(*                  This file is part of Waterproof-lib.                      *)
(*                                                                            *)
(*   Waterproof-lib is free software: you can redistribute it and/or modify   *)
(*    it under the terms of the GNU General Public License as published by    *)
(*     the Free Software Foundation, either version 3 of the License, or      *)
(*                    (at your option) any later version.                     *)
(*                                                                            *)
(*     Waterproof-lib is distributed in the hope that it will be useful,      *)
(*      but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the         *)
(*               GNU General Public License for more details.                 *)
(*                                                                            *)
(*     You should have received a copy of the GNU General Public License      *)
(*   along with Waterproof-lib. If not, see <https://www.gnu.org/licenses/>.  *)
(*                                                                            *)
(******************************************************************************)

Require Import Ltac2.Ltac2.

Require Import Waterproof.Util.Constr.
Require Import Waterproof.Util.Goals.
Require Import Waterproof.Tactics.Unfold.

Ltac2 Type exn ::= [ GoalCheckError(string) ].

Local Ltac2 idtac () := ().

(**
  Check if the type of the goal is syntactically equal to [t].

  Arguments:
    - [t: constr], any constr to be compared against the goal.

  Does:
    - Prints a confirmation that the goal equals the provided type.
    
  Raises Exceptions:
    - [GoalCheckError], if the goal is not syntactically equal to [t].
*)
Local Ltac2 check_goal := fun (t:constr) =>
  lazy_match! goal with
    | [ |- ?g] => 
      match check_constr_equal g t with
        | true => idtac ()
                  (* print (concat (of_string "The goal is indeed: ") (of_constr t))*)
        | false => Control.zero (GoalCheckError "Wrong goal specified.")
      end
    | [|-_] => Control.zero (GoalCheckError "Wrong goal specified.")
  end.

(**
  Check if the type of the goal is convertible to [t], if so, it replaces the goal by t.

  Arguments:
    - [t: constr], any constr to be compared against the goal.

  Does:
    - Prints a confirmation that the goal equals the provided type.
    
  Raises Exceptions:
    - [GoalCheckError], if the goal is not convertible to [t].
*)
Local Ltac2 check_and_change_goal (t:constr) :=
  lazy_match! goal with
    | [ |- ?g] => 
      match check_constr_equal g t with
        | true =>
          idtac ();
          change $t
        | false => Control.zero (GoalCheckError "Wrong goal specified.")
      end
    | [|-_] => Control.zero (GoalCheckError "Wrong goal specified.")
  end.


(**
  Attempts to remove the [StateGoal.Wrapper] wrapper from the goal.
    
  Arguments:
    - [t : constr], type matching the wrapped goal.
    
  Does: 
    - Removes the wrapper if the argument matches the wrapped goal, i.e. the goal is of the form [StateGoal.Wrapper t].

  Raises Exceptions:
    - [GoalCheckError], if the argument [t] does not match the wrapped goal.
*)
Local Ltac2 unwrap_state_goal (t : constr) :=
  lazy_match! goal with
    | [|- StateGoal.Wrapper ?g] =>
      match (check_constr_equal g t) with
        | true  => apply StateGoal.wrap
        | false => Control.zero (GoalCheckError "Wrong goal specified.")
      end
    | [|- _] => idtac ()
  end.

(**
  1) If the goal is wrapped in [ExpandDef.Goal.Wrapper], attempt to remove the wrapper.
  
  2) Else if the goal is wrapped in [State.Goal.Wrapper], attempt to remove it.
  
  3) Else, check if the type of the goal is convertible to [t], if so, it replaces the goal by t.

  Arguments:
    - [t: constr]
      1,2) type matching the wrapped goal.
      3) any constr to be compared against the goal.

  Does:
    - 1,2) Removes the wrapper if the argument matches the wrapped goal, i.e. the goal is of the form [ExandDef.Goal.Wrapper t] ([StateGoal.Wrapper t] resp.).
    - 3) Prints a confirmation that the goal equals the provided type.
    
  Raises Exceptions:
    - 1) [ExpandDefError], if the argument [t] does not match the wrapped goal.
    - 2) [GoalCheckError], if the argument [t] does not match the wrapped goal.
    - 3) [GoalCheckError], if the goal is not convertible to [t].
*)
Local Ltac2 unwrap_or_check_and_change_goal (t : constr) :=
  lazy_match! goal with
    | [|- ExpandDef.Goal.Wrapper _] => goal_as t; change $t (*[goal_as] is from unfold.v*)
    | [|- StateGoal.Wrapper _] => unwrap_state_goal t; change $t
    | [|- _] => panic_if_goal_wrapped (); check_goal t; change $t
  end.

(*
  Allow different syntax styles:
    - We need to show ...
    - We need to show that ...
    - We need to show : ...
    - We need to show that : ...
    - To show ...
    - To show that ...
    - To show : ...
    - To show that : ...

  Optional string keywords do need to have a name, even though the parser will not populate this name. 
  (That's why it reads "that(opt('that'))" instead of "opt('that')".
*)
Ltac2 Notation "We" "need" "to" "show" that(opt("that")) colon(opt(":")) t(constr) := unwrap_or_check_and_change_goal t.

Ltac2 Notation "To" "show" that(opt("that")) colon(opt(":")) t(constr) := unwrap_or_check_and_change_goal t.
