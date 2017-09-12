package rss.web;

import php.Web;

import rss.db.*;
using StringTools;

class Index {

	public static function main() {
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
		}

		var feed = Feed.fromId(Std.parseInt(Web.getParams().get("feed")));

		// Get new items corresponding to the last retrieved one 
		// TODO cap at max per page
		if (params.exists("newSince")) {
			var newSince = Std.parseInt(params.get("newSince"));
			if (newSince == null) {newSince = -1; }
			newItemsSince(feed, newSince);
		}
		
		var id = Std.parseInt(params.get("id"));
		if (id == null) { id = -1; }
		
		var showread = (params.exists("showread")) ? params.get("showread") == "true": true;
		var dir = (params.exists("dir")) ? params.get("dir") == "true": true;

		untyped __php__('date_default_timezone_set("Europe/Paris")');

		Sys.println('<!DOCTYPE html>\n<html>\n\t<head>
		<meta charset="utf-8" />
			<link rel="stylesheet" href="main.css"/>
			<script type="text/javascript" src="main.js" charset="utf-8"></script>
			<title>Titre</title>
		</head>
		<body>');
		listFeeds();
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
		Sys.println('<article id="feed-${feed==null ? 0 : feed.id}">');
		if (list.length > 0) {
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
			Sys.println("<ul>\n</ul>");
		}
		Sys.println("</article>");
	}

	public static function listFeeds() {
		var unreadcount = Item.countUnread(null);
		Sys.println('<nav><ul id="feedlist">');
		Sys.println('<li><a href="index.php?feed=0">All&nbsp;</a><span id="unreadcount-0">${unreadcount == 0 ? "" : ""+unreadcount}</li>');
		for (feed in Feed.all()) {
			Sys.println(feed.html);
		}
		Sys.println('</ul>\n<form action="/index.php" method="get">
		<input id="new" name="new" type="text"/>
		<!--<input value="Add" type="submit"/>-->
		<button onclick="addFeed()" type="button">Add</button>\n</form>\n</nav>');
	}
}