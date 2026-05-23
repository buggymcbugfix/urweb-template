
val fetchInto [a] (src : source a) (txn : transaction a) =
	<xml>
		<active code={
			spawn
				(
					data <- rpc txn;
					set src data
				);
			return <xml/>
		}/>
	</xml>
