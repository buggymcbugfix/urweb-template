type ty
val show_ty : show ty
val sql_ty : sql_injectable_prim ty
type delta
val show_delta : show delta
val sql_delta : sql_injectable_prim delta
val toDelta : ty -> delta
val fromDelta : delta -> ty
val applyDelta : delta -> ty -> ty
val testPage : transaction page

