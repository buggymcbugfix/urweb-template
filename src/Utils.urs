val fetchInto : a ::: Type -> source a -> transaction a -> xbody
(* val deriveShow : a :: Type -> show a *)
val show_serialized : a ::: Type -> show a -> show (serialized a)
