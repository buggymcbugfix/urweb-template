val hello name = return <xml><body>Hello, {[name]}!</body></xml>

val renderTransactionTr r =
	<xml>
		<tr>
			<td>{[r.Timestamp]}</td>
			<td>{[r.Delta]}</td>
			<td>{[r.Balance]}</td>
			<td>{[show (deserialize r.Category)]}</td>
			<td>{[r.Description]}</td>
		</tr>
	</xml>

val myTransactions userId =
	txns <- Txn.getForUser userId;
	return
		<xml>
			<head>
				<link rel="stylesheet" type="text/css" href="/css/main.css"/>
			</head>
			<body>
				<table>
					<tr>
						<th>Date</th>
						<th>Delta</th>
						<th>Balance</th>
						<th>Category</th>
						<th>Description</th>
					</tr>
					{List.mapX renderTransactionTr txns}
				</table>
			</body>
		</xml>

val renderUserRow r =
	<xml>
		<li>
			<a link={myTransactions r.UserId}>{[r.Username]}</a>
		</li>
	</xml>

val users =
	(users : list $User.row) <- User.getAll;
	return
		<xml>
			<body>
				<ul>
					{List.mapX renderUserRow users}
				</ul>
			</body>
		</xml>

val index =
	return
		<xml>
			<body>
				<h1>Bank of Dad</h1>
				<ul>
					<li><a link={hello "World"}>hello world</a></li>
					<li><a link={users}>list of all users</a></li>
					(* <li><a link={myTransactions 1}>transactions for user 1</a></li> *)
				</ul>
				<span style="display:none">@GIT_REV@</span>
			</body>
		</xml>
