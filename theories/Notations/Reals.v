Require Import Coq.Reals.Reals.
Require Import Qreals.

Require Import Waterproof.Notations.Common.
Require Import Waterproof.Notations.Sets.

(** ** (In)equalities
  Allowing unicode characters for uniqualities.
*)
Notation "x ≠ y" := (x <> y) (at level 70) : type_scope.
Notation "x ≤ y" := (le x y) (at level 70, no associativity) : nat_scope.
Notation "x ≥ y" := (ge x y) (at level 70, no associativity) : nat_scope.
Notation "x ≤ y" := (x <= y)%R (at level 70, no associativity) : R_scope.
Notation "x ≥ y" := (x >= y)%R (at level 70, no associativity) : R_scope.

Open Scope nat_scope.
Open Scope R_scope.

(** ** Scopes and coercions *)
Notation "'ℕ'" := (nat).
Notation "'ℤ'" := (Z).
Notation "'ℚ'" := (Q).
Notation "'ℝ'" := (R).

(* We use coercions to get around writing INR and IZR *)
Coercion INR: nat >-> R.
Coercion IZR: Z >-> R.
Coercion Q2R: Q >-> R.

(** ** Sequences *)
Definition converges_to (a : ℕ → ℝ) (c : ℝ) :=
  ∀ ε : ℝ, ε > 0 ⇒
    ∃ N : ℕ, ∀ n : ℕ, (n ≥ N)%nat ⇒
      R_dist (a n) c < ε.

Notation "a ⟶ c" := (converges_to a c) (at level 20).

Definition cv_implies_cv_abs_to_l_abs := cv_cvabs.

(** * Real numbers

  We have to take care with the associative level.
  When using this in rewrites, $<$, $>$, etc. should bind stronger.
*)

Declare Scope extra.

Notation "| x |" := (Rabs x) (at level 65, x at next level, format "| x |").
Notation "｜ x - y ｜" := (R_dist x y) (at level 65, x at level 48, y at level 48, format "｜ x  -  y ｜") : extra.


(** ** Sums and series *)
Notation "'Σ' Cn 'equals' x" := (infinite_sum Cn x) (at level 50).

Definition finite_triangle_inequalty := sum_f_R0_triangle.

(** ** Subsets and intervals*)
Notation "[ a , b ]" := (as_subset R (fun x => (a <= x <= b))).
Notation "[ a , b )" := (as_subset R (fun x => (a <= x <  b))).
Notation "( a , b ]" := (as_subset R (fun x => (a <  x <= b))).
Notation "( a , b )" := (as_subset R (fun x => (a <  x <  b))).

Close Scope nat_scope.
Close Scope R_scope.