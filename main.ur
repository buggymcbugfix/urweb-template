val mkPage (x : xbody) =
	<xml>
		<head>
			<link rel="stylesheet" type="text/css" href="/css/main.css"/>
		</head>
		<body>
			{x}
		</body>
	</xml>

val returnMkPage = return <<< mkPage

val hello name = returnMkPage <xml>Hello, {[name]}!</xml>

val renderTransactionTr r =
	<xml>
		<tr class={if Money.Delta.isNegative r.Delta then Class.negative else Class.positive}>
			<td>{[timef "%Y-%m-%d (%a)" (Date.toTime r.EffectiveDate)]}</td>
			<td class={Class.right_aligned}>{[r.Delta]}</td>
			<td class={Class.right_aligned}>{[r.Balance]}</td>
			<td>{[r.Category]}</td>
			<td>{[r.Description]}</td>
		</tr>
	</xml>

val renderPendingTransactionTr r =
	<xml>
		<tr class={if Money.Delta.isNegative r.Delta then Class.negative else Class.positive}>
			<td>{[timef "%Y-%m-%d (%a)" (Date.toTime r.EffectiveDate)]}</td>
			<td class={Class.right_aligned}>{[r.Delta]}</td>
			<td class={Class.right_aligned}>⏳</td>
			<td>{[r.Category]}</td>
			<td>{[r.Description]}</td>
		</tr>
	</xml>

val myTransactions userId =
	PocketMoney.collect userId;
	user <- User.get userId;
	txns <- Txn.getForUser userId;
	today <- Date.today;
	scPendingTxns <- source [];
	scTxns <- source txns;
	returnMkPage
		<xml>
			<h1>Transactions for {[user.Username]}</h1>
			<active code={
				scEffectiveDate <- source (show today);
				scDelta <- source None;
				scCategory <- source "";
				scDescription <- source "";
				return
					<xml>
						<div class={Class.ui_group}>
							<cnumber source={scDelta} step=0.01 />
							<cdate source={scEffectiveDate}/>
							<cselect source={scCategory}>
								{
									List.mapX
										(fn cat => <xml><coption value={show cat}>{[cat]}</coption></xml>)
										Txn.Category.enumerate
								}
							</cselect>
							<ctextbox source={scDescription}/>
							<button onclick={
								fn _ =>
									effectiveDate <- get scEffectiveDate;
									delta <- get scDelta;
									category <- get scCategory;
									description <- get scDescription;
									let
										val r =
											{
												UserId = userId,
												EffectiveDate = readError effectiveDate,
												Delta = readError (show (100. * Option.get 0. delta)),
												Category = deserialize (unsafeSerializedFromString category),
												Description = description
											}
									in
										pendingTxns <- get scPendingTxns;
										set scPendingTxns (r :: pendingTxns);
										rpc (Txn.create r);
										txns <- rpc (Txn.getForUser userId);
										set scTxns txns;
										set scPendingTxns []
									end
							}>
								submit
							</button>
						</div>
					</xml>
			}/>
			<active code={
				return
					<xml>
					<table>
						<tr>
							<th>Date</th>
							<th>Delta</th>
							<th>Balance</th>
							<th>Category</th>
							<th>Description</th>
						</tr>
						<dyn signal={
							txns <- signal scPendingTxns;
							return (List.mapX renderPendingTransactionTr txns)
						}/>
						<dyn signal={
							txns <- signal scTxns;
							return (List.mapX renderTransactionTr txns)
						}/>
						</table>
					</xml>
			}/>
			(* <button onclick={fn _ => rpc (PocketMoney.collect userId)}>Collect</button> *)
		</xml>

val renderUserRow r =
	<xml>
		<li>
			<a link={myTransactions r.UserId}>{[r.Username]}</a>
		</li>
	</xml>

val users =
	(users : list $User.row) <- User.getAll;
	returnMkPage
		<xml>
			<ul>
				{List.mapX renderUserRow users}
			</ul>
		</xml>

val index =
	returnMkPage
		<xml>
			<h1>Bank of Dad</h1>
			<ul>
				<li><a link={hello "World"}>hello world</a></li>
				<li><a link={users}>list of all users</a></li>
			</ul>
			<span style="display:none">@GIT_REV@</span>
		</xml>
