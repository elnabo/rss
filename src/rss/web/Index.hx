package rss.web;

import php.Web;

import rss.db.*;
using StringTools;

class Index {

	private static var baseurl = "index.php";
	private static var option = [];

	public static function main() {
		untyped __php__('date_default_timezone_set("Europe/Paris")');

		if (!DB.init()) {

		}
		var params = Web.getParams();

		// Count new item in all feed
		if (params.exists("count")) {
			countUnread();
		}

		// Mark an item as read/unread
		if (params.exists("mark")) {
			var read = Std.parseInt(params.get("mark"));
			var value = (params.exists("value")) ? params.get("value") == "true" : true;

			if (read != null) {
				Item.markAsRead(read, value);
				Sys.print('$read is ${value ? "read" : "unread"}');
				Sys.exit(0);
			}

			Sys.print("Error");
			Sys.exit(0);
		}

		// Mark all item from a feed as read
		if (params.exists("markAll")) {
			var feed = Std.parseInt(params.get("markAll"));
			if (feed != null) {
				Feed.readAll(Feed.fromId(feed));
				Sys.print("OK");
				Sys.exit(0);
			}
			Sys.print("Error");
			Sys.exit(0);
		}

		// Track a new feed
		if (params.exists("new")) {
			var newFeed = params.get("new");
			if (newFeed != null) {
				var link = newFeed.urlDecode();
				var process = new sys.io.Process("neko main.n --add "+ link);
				var code = process.exitCode(true);
				switch (code) {
					case 0:
						var feed = Feed.fromLink(link);
						Sys.print('${feed.title} ${feed.id}');
					case 3:
						Sys.print("Exists");
					default: 
						Sys.print("Error");
				}
				Sys.exit(0);
			}
			Sys.print("Error");
			Sys.exit(0);
		}

		var feed = null;
		if (params.exists("feed")) {
			var v = params.get("feed");
			option.push("feed="+v);
			feed = Feed.fromId(Std.parseInt(v));
		}


		// Get new items corresponding to the last retrieved one 
		// TODO cap at max per page
		if (params.exists("newSince")) {
			var v = params.get("newSince");
			option.push("newSince="+v);
			var newSince = Std.parseInt(v);
			if (newSince == null) {newSince = -1; }
			newItemsSince(feed, newSince);
		}
		
		var id = -1;
		if (params.exists("id")){
			var v = params.get("id");
			option.push("id="+v);
			id = Std.parseInt(v);
			if (id == null) {id = -1;}
		}
		
		var showread = false;
		if (params.exists("showread")) {
			var v = params.get("showread");
			// not stored
			// option.push("showread="+v);
			showread = v == "true";
		}

		var dir = true;
		if (params.exists("dir")) {
			var v = params.get("dir");
			option.push("dir="+v);
			showread = v == "true";
		}

		Sys.println('<!DOCTYPE html>\n<html>\n\t<head>
		<meta charset="utf-8" />
			<link rel="stylesheet" href="main.css"/>
			<script type="text/javascript" src="main.js" charset="utf-8"></script>
			<title>Titre</title>
		</head>
		<body>');
		listFeeds(showread);
		listItems(feed, showread, dir, id);

		Sys.print('\t</body>\n</html>');

	}

	public static function countUnread() {
		var feeds = [0];
		var counts = [0];

		for (feed in Feed.all()) {
			var c = Item.countUnread(feed);
			feeds.push(feed.id);
			counts.push(c);
			counts[0] += c;
		}
		Sys.print(feeds.join(" ") + "\n" + counts.join(" "));
		Sys.exit(0);
	}

	public static function newItemsSince(feed:Feed, id:Int) {
		var html = Item.newSinceId(feed, id).map(
			function(i:Item) { return i.html; }).join("\n");
		Sys.println(html);
		Sys.exit(0);
	}


	public static function listItems(?feed:Feed, ?read:Bool=false, ?dir:Bool=true, ?id:Int=-1) {
		var page = Item.pageChange(id,feed,dir,25,read);
		var list = page.list;

		option.push("showread="+(!read));
		var toggleReadURL = baseurl + "?" + option.join("&");
		var toggleButton = '<a id="${read ? "show" : "hide"}-read" href=${toggleReadURL}>${read ? "Hide" : "Show"} read</a>';
		
		Sys.println('<article id="feed-${feed==null ? 0 : feed.id}">');
		if (list.length > 0) {
			Sys.println(toggleButton);
			var left = 'index.php?feed=${(feed == null) ? 0 : feed.id}&id=${list.first().id}&dir=false&showread=${read}';
			var right = 'index.php?feed=${(feed == null) ? 0 : feed.id}&id=${list.last().id}&dir=true&showread=${read}';
			if (page.remainingLeft) {
				Sys.println('<a id="top-left" href=$left> Left</a>');
			}
			else {
				Sys.println('<span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>');
			}
			if (page.remainingRight) {
				Sys.println('<a id="top-right" href=$right> Right</a>');
			}
			Sys.println("<ul>");
			for (item in list) {
				Sys.println(item.html);
			}
			Sys.println("</ul>");
		}
		else {
			var lastId = Item.lastId();
			Sys.println(toggleButton);
			Sys.println("<ul>");
			Sys.println('<li id="item-${lastId}" class="${feed==null ? 0 :feed.id} item read" style="display:none;"/>');
			Sys.println("</ul>");
		}
		Sys.println("</article>");
	}

	public static function listFeeds(?read=false) {
		var unreadcount = Item.countUnread(null);
		var showread = "&showread="+read;
		Sys.println('<nav><ul id="feedlist">');
		Sys.println('<li><a href="index.php?feed=0$showread">All&nbsp;</a><span id="unreadcount-0">${unreadcount == 0 ? "" : ""+unreadcount}</span><button class="readAll" onclick="markAllAsRead(0)">Read</button></li>');
		for (feed in Feed.all()) {
			Sys.println(feed.toHtml(showread));
		}
		Sys.println('</ul>\n<form action="/index.php" method="get">
		<input id="new" name="new" type="text"/>
		<!--<input value="Add" type="submit"/>-->
		<button onclick="addFeed()" type="button">Add</button>\n</form>\n</nav>');
	}
}