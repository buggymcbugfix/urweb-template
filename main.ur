val gitRev = return <xml><body>@GIT_REV@</body></xml>

val hello name = return <xml><body>Hello, {[name]}!</body></xml>

val renderUserTr r =
	<xml>
		<tr>
			<td>{[r.UserId]}</td>
			<td>{[r.Username]}</td>
		</tr>
	</xml>

val users =
	srcUsers <- source [];
	return
		<xml>
			<body>
				(* {fetchInto srcUsers User.getAll} *)
				<active code={
					spawn
						(
							data <- rpc User.getAll;
							set srcUsers data
						);
					return <xml/>
				}/>
				<table>
				<tr><th>ID</th><th>Username</th></tr>
				<dyn signal={
					users <- signal srcUsers;
					return (List.mapX renderUserTr users)
				}/>
				</table>
			</body>
		</xml>

(* Version of [users] that is easier to understand *)
val users' =
	(users : list $User.row) <- User.getAll;
	return
		<xml>
			<body>
				<table>
					<tr><th>User ID</th><th>Username</th></tr>
					{List.mapX renderUserTr users}
				</table>
			</body>
		</xml>

val renderTransactionTr r =
	<xml>
		<tr>
			<td>{[r.Timestamp]}</td>
			<td>{[Money.fmt r.Delta]}</td>
			<td>{[Money.fmt r.Balance]}</td>
			<td>{[show (deserialize r.Category)]}</td>
			<td>{[r.Description]}</td>
		</tr>
	</xml>

val myTransactions userId =
	txns <- Txn.getForUser userId;
	return
		<xml>
			<body>
				<table>
					<tr>
						<th>Timestamp</th>
						<th>Delta</th>
						<th>Balance</th>
						<th>Category</th>
						<th>Description</th>
					</tr>
					{List.mapX renderTransactionTr txns}
				</table>
			</body>
		</xml>

val index =
	return
		<xml>
			<body>
				<ul>
					<li><a link={gitRev}>git hash</a></li>
					<li><a link={hello "World"}>hello world</a></li>
					<li><a link={users}>list of all users</a></li>
					<li><a link={Money.testPage}>play with money</a></li>
					(* <li><a link={myTransactions 1}>transactions for user 1</a></li> *)
				</ul>
			</body>
		</xml>
