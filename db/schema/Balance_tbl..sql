CREATE TABLE Balance_tbl (
	UserId integer NOT NULL PRIMARY KEY REFERENCES User_tbl(UserId),
	Balance integer NOT NULL
)
;
