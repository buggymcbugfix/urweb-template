type id
val show_id : show id
val sql_id : sql_injectable_prim id

con row =
	[
		UserId = id,
		Username = string,
	]

table tbl :
	row
	PRIMARY KEY UserId,
	CONSTRAINT Uq_Username UNIQUE Username

val getAll : transaction (list $row)
val get : id -> transaction $row
