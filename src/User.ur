type id = int
val show_id = show_int
val sql_id = sql_int

con row =
	[
		UserId = id,
		Username = string,
	]

table tbl :
	row
	PRIMARY KEY UserId,
	CONSTRAINT Uq_Username UNIQUE Username

val getAll = queryL1 (SELECT * FROM tbl ORDER BY tbl.Username)
