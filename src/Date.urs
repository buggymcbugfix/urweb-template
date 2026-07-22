type ty
val show : show ty
val read : read ty
val ord : ord ty
val sql_injectable : sql_injectable_prim ty
val sql_maxable : sql_maxable ty
val today : transaction ty
val unixEpoch : ty
val fromTime : time -> ty
val toTime : ty -> time
val addDays : int -> ty -> ty
(* val testPage : transaction page *)
