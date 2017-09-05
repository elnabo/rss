package rss.server;

import rss.db.DB;
import rss.db.Feed;

import sys.FileSystem;
import sys.io.File;

using StringTools;

class Main {

	public static function main() {

		var p = new sys.io.Process("echo $PPID");
		var pid = (p.stdout.readAll().toString());

		var lock = "lock";
		if (FileSystem.exists(lock)) {
			var lockpid = File.getContent(lock).trim();
			if (FileSystem.exists("/proc/"+lockpid)) {
				Sys.exit(0);
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

		for (feed in Feed.all()) {
			new RSS(feed.link);
			trace("Updated: "+feed.title);
		}
		FileSystem.deleteFile(lock);
	}
}
