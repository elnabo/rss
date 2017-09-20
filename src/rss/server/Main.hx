package rss.server;

import rss.db.DB;
import rss.db.Feed;

import sys.FileSystem;
import sys.io.File;

using StringTools;

class Main {

	/* Exit:
		0 : Succes
		1 : Error
		2 : Locked
		3 : Feed already exist
	*/
	public static function main() {
		var args = Sys.args();
		if (args.length > 0 && args[0] == "--add") {
			if (args.length >= 2) {
				if (!DB.init()) { 
					Sys.exit(1);
				}
				var rss = new RSS(args[1], false, false, false);
				if (rss.feed == null) {
					Sys.exit(1);
				}
				Sys.exit(rss.created ? 0 : 3);
			}
			Sys.exit(1);
		}

		var p = new sys.io.Process("echo $PPID");
		var pid = (p.stdout.readAll().toString());

		var path = Sys.programPath().split("/");
		path.pop();
		path.push("lock");
		var lock = path.join("/");
		if (FileSystem.exists(lock)) {
			var lockpid = File.getContent(lock).trim();
			if (FileSystem.exists("/proc/"+lockpid)) {
				Sys.exit(2);
			}
			else {
				FileSystem.deleteFile(lock);
			}
		}

		File.saveContent(lock, pid);
		
		if (!DB.init()) { 
			FileSystem.deleteFile(lock);
			Sys.exit(1);
		}

		// new RSS("https://www.betaseries.com/rss/planning/elnabo");

		for (feed in Feed.all()) {
			new RSS(feed.link);
			trace("Updated: "+feed.title);
		}
		FileSystem.deleteFile(lock);
	}
}
