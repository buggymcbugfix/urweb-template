table weeklyAmount :
	[
		UserId = User.id,
		Amount = Money.ty,
		Starting = Date.ty,
	]
	PRIMARY KEY (UserId, Starting)

val getLatestPocketMoneyTxn userId : transaction (option Date.ty) =
	let
		val txn = Txn.tbl
	in
		latest <-
			oneOrNoRowsE1
				(
					SELECT MAX(txn.EffectiveDate) AS LatestEffectiveDate
					FROM txn
					WHERE txn.Category = {[serialize Txn.Category.PocketMoney]}
						AND txn.UserId = {[userId]}
				);
		case latest of
		| Some (Some latest) => return (Some latest)
		| _ => return None
	end

val collectNextFromGivenDate r =
	today <- Date.today;
	if r.NextPayday <= today then
		amt <-
			oneOrNoRowsE1
				(
					SELECT weeklyAmount.Amount AS Amount
					FROM weeklyAmount
					WHERE weeklyAmount.Starting <= {[r.NextPayday]}
					ORDER BY weeklyAmount.Starting DESC
					LIMIT 1
				);
		(
			case amt of
			| None => return False
			| Some amt =>
				Txn.create
					{
						UserId = r.UserId,
						EffectiveDate = r.NextPayday,
						Delta = Money.toDelta amt,
						Category = Txn.Category.PocketMoney,
						Description = ""
					};
				return True
		)
	else
		return False

val collectNext userId =
	latest <- getLatestPocketMoneyTxn userId;
	case latest of
	| Some latest => collectNextFromGivenDate {UserId = userId, NextPayday = Date.addDays 7 latest}
	| None =>
		startDate <-
			oneOrNoRowsE1
				(
					SELECT weeklyAmount.Starting AS Starting
					FROM weeklyAmount
					WHERE weeklyAmount.UserId = {[userId]}
					ORDER BY weeklyAmount.Starting ASC
					LIMIT 1
				);
		case startDate of
		| Some startDate =>
			collectNextFromGivenDate {UserId = userId, NextPayday = startDate}
		| None =>
			return False
			(* error <xml>No weekly amount configured for user {[userId]}</xml> *)

fun collect userId =
	res <- collectNext userId;
	case res of
	| True => collect userId
	| False => return {}
