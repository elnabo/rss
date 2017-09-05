package rss.db;

import sys.db.Types;

@:id(id)
class Feed extends sys.db.Object {
	public var id:SId;
	public var link:String;
	public var descr:String;
	public var title:String;

	public function getId() { return id; }

	@:skip
	public var justCreated = false;

	@:skip
	public var html(get, never):String;
	public function get_html() {
		return '<li><a href="index.php?feed=${id}">${title}</a></li>';
	}

	public static function create(link:String, descr:String, title:String, ?log:Bool=true) {
		var match = Feed.manager.search($link == link);
		if (match.isEmpty()) {
			var feed = new Feed();
			feed.link = link;
			feed.descr = descr;
			feed.title = title;
			feed.insert();
			if (log) {
				trace("New feed added: ", title, link);
			}
			feed.justCreated = true;
			return feed;
		}
		else {
			return match.first();
		}
	}

	public static function all() : List<Feed> {
		return manager.search(1==1, {orderBy:title});
	}

	public static function fromLink(link:String) {
		return manager.search($link == link).first();
	}

	public static function fromId(id:SId) {
		return manager.search($id == id).first();
	}

	public static function deleteFeed(feed:Feed) {
		for (item in Item.from(feed)) {
			item.delete();
		}
		feed.delete();
	}
}
