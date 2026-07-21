type ty = string

table faux : [Today = ty]

val today = oneRowE1 (SELECT (faux.Today) FROM faux)

val show = show_string
