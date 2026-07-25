type ty
val show_ty : show ty
val sql_ty : sql_injectable_prim ty

structure Delta : sig
	type ty
	val show : show ty
	val read : read ty
	val sql_delta : sql_injectable_prim ty
	val isNegative : ty -> bool
end

val toDelta : ty -> Delta.ty
val fromDelta : Delta.ty -> ty
val applyDelta : Delta.ty -> ty -> ty

val testPage : transaction page

