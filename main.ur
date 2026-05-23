open Utils

val gitRev = return <xml><body>@GIT_REV@</body></xml>

val hello name = return <xml><body>Hello, {[name]}!</body></xml>

val index = hello "World"

val renderUserTr r =
	<xml>
		<tr>
			<th>{[r.UserId]}</th>
			<th>{[r.Username]}</th>
			<th>{[r.FirstName]}</th>
			<th>{[r.LastName]}</th>
		</tr>
	</xml>

val users =
	srcUsers <- source [];
	return
		<xml>
			<body>
				{fetchInto srcUsers User.getAll}
				<table>
				<tr><th>ID</th><th>Username</th><th>First Name</th><th>Last Name</th></tr>
				<dyn signal={
					users <- signal srcUsers;
					return (List.mapX renderUserTr users)
				}/>
				</table>
			</body>
		</xml>
