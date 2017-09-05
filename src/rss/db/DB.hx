package rss.db;

class DB {
	static var db(default, never) = "rss.db";
	public static function init() {
		try {
			sys.db.Manager.cnx = sys.db.Sqlite.open(db);
			if ( !sys.db.TableCreate.exists(Feed.manager) ){
				sys.db.TableCreate.create(Feed.manager);
			}
			if ( !sys.db.TableCreate.exists(Item.manager) ){
				sys.db.TableCreate.create(Item.manager);
			}

			return true;
		}
		catch (e:Dynamic) {
			trace(e);
			return false;
		}
	}
}