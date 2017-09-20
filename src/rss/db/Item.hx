package rss.db;

import sys.db.Types;

typedef Page = {list:List<Item>, remainingLeft:Bool, remainingRight:Bool};

@:id(id)
class Item extends sys.db.Object {
	public var id:SId;
	public var link:String;
	public var descr:String;
	public var title:String;
	public var pubDate:String;
	public var updated:STinyInt;

	@:relation(source_id)
	public var source:Feed;
	public var timestamp:Float;
	public var read:STinyInt;

	@:skip
	public var isRead(get,never):Bool;
	private function get_isRead() {
		#if php
		return read-1 == 0;
		#else
		return read == 1;
		#end
	}

	@:skip
	public var date(get,never):String;
	private function get_date() {
		return DateTools.format(Date.fromTime(timestamp), "%e %b %Y - %H:%M");
	}

	@:skip
	public var html(get, never):String;
	public function get_html() {
		return '<li id="item-${id}" class="${source.getId()} item ${isRead ? "read" : ""}" timestamp="${timestamp}">
	<h1>
		<span class="feed_title">${source.title}</span>
		<span class="date">${date}</span>
		<button id="mark-${id}" class="mark" type="button" onclick="markAsRead(${id})">Mark as read</a>
	</h1>
	<div class="title"><a href="${link}">${title}</a></div>
	<div class="descr">${descr}</div>
</li>';
	}

	public static function create(link:String, descr:String, title:String, pubDate:String, source:Feed, ?asRead:Bool=false, ?log:Bool=true) {
		var match = manager.search($link == link && $descr == descr && $title == title && $source == source);
		if (match.isEmpty()) {
			var item = new Item();
			item.link = link;
			item.descr = descr;
			item.title = title;
			item.pubDate = pubDate;
			item.source = source;
			item.timestamp = Date.now().getTime();
			item.read = (asRead) ? 1 : 0;
			item.updated = 0;
			item.insert();
			if (log) {
				trace("new item ", source);
			}
			return item;
		}
		else {
			var exactMatch = manager.search($link == link && $descr == descr && $title == title && $source == source && $pubDate == pubDate);
			if (exactMatch.isEmpty()) {
				var item = new Item();
				item.link = link;
				item.descr = descr;
				item.title = title;
				item.pubDate = pubDate;
				item.source = source;
				item.timestamp = Date.now().getTime();
				item.read = (asRead) ? 1 : 0;
				item.updated = 1;
				item.insert();
				if (log) {
					trace("new item ", source);
				}
				return item;
			}
			return match.first();
		}
	}

	public static function markAsRead(id:SId, ?value:Bool=true) {
		var match = manager.search($id == id);
		if (!match.isEmpty()) { 
			var item = match.first();
			item.read = value ? 1 : 0;
			item.update();
		}
	}
	
	public static function get(link:String, descr:String, title:String, pubDate:String, source:Feed) {
		return manager.search($link == link && $descr == descr && $title == title && $pubDate == pubDate && $source == source).first();
	}

	public static function all() : List<Item> {
		return manager.search(1==1, {orderBy:[-timestamp, id]});
	}

	public static function laterThan(timestamp:Float) {
		return manager.search($timestamp > timestamp, {orderBy:[-timestamp, id]});
	}

	public static function earlierThan(timestamp:Float) {
		return manager.search($timestamp <= timestamp, {orderBy:[timestamp, id]});
	}

	public static function from(?feed:Feed=null) : List<Item> {
		return (feed == null) ? Item.all() : manager.search($source == feed, {orderBy:-timestamp});
	}

	public static function unread() : List<Item> {
		return manager.search($read == 0, {orderBy:[-timestamp, id]});
	}

	public static function unreadFrom(?feed:Feed) : List<Item> {
		return (feed == null) ? Item.unread() : manager.search($source == feed && $read == 0, {orderBy:-timestamp});
	}

	public static function newSinceMinutes(ago:Int) {
		var t = Date.now().getTime() - 1000 * 60 * ago;
		return laterThan(t);
	}

	public static function newSinceId(feed:Feed, id:SId) {
		var list = from(feed);
		if (id == -1) {
			return list;
		}

		do {
			var last = list.last();
			list.remove(list.last());
			if (last.id == id) {
				break;
			}
		} while (list.length > 0);
		return list;
	}

	public static function pageChange(id:SId, feed:Feed, after:Bool, ?count:Int=25, ?read:Bool=false) {
		var list = from(feed);
		var index = 0;
		var found = false;
		for (item in list) {
			if (item.id == id) {
				found = true;
				break;
			}
			index++;
		}

		if (!after) {
			index = list.length - index;
		}

		var remainingLeft = false;
		var remainingRight = false;

		if (found) {
			while (index >= 0) {
				var item = listRemove(list, after);
				if (read || !item.isRead) {
					if (after) {
						remainingLeft = true;
					}
					else {
						remainingRight = true;
					}
				}
				index--;
			}
		}

		var page = [];
		while (list.length > 0 && page.length < count) {
			var item = (after) ? list.first() : list.last();

			list.remove(item);
			if (read || !item.isRead) {
				if (after) {
					page.push(item);
				}
				else {
					page.unshift(item);
				}
			}
		}

		while (list.length > 0) {
			var item = (after) ? list.first() : list.last();
			if (read || !item.isRead) {
				if (after) {
					remainingRight = true;
				}
				else {
					remainingLeft = true;
				}
				break;
			}
		}

		var res = new List<Item>();
		for (item in page) {
			res.add(item);
		}
		return {list:res, remainingLeft:remainingLeft, remainingRight:remainingRight};
	}

	public static function listRemove (list:List<Item>, removeFirst:Bool) {
		var item = (removeFirst) ? list.first() : list.last();
		list.remove(item);
		return item;
	}

	public static function countUnread(feed:Feed) {
		return (feed == null) ? manager.count($read ==0) : manager.count($source == feed && $read ==0);
	}

	public static function lastId() {
		var i = all().first();
		return (i == null) ? 0 : i.id;
	}
}
