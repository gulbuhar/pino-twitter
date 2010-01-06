/* template.vala
 *
 * Copyright (C) 2009  troorl
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 * 	troorl <troorl@gmail.com>
 */

using Gee;
using GLib;

class Template : Object {
	
	public Cache cache;
	
	private string mainTemplate;
	private string statusTemplate;
	private string statusMeTemplate;
	
	private Regex nicks;
	private Regex tags;
	private Regex urls;
	
	public Template() {
		reload();
		
		//compile regex
		nicks = new Regex("@([A-Za-z0-9_]+)");
		tags = new Regex("(\\#[A-Za-z0-9_]+)");
		urls = new Regex("((http|https|ftp)://([\\S]+))"); //need something better
		
		cache = new Cache();
	}
	
	public string generateFriends(Gee.ArrayList<Status> friends,
		SystemStyle gtkStyle, Prefs prefs, int last_focused) {
		string content = "";
		
		var now = get_current_time();
		
		var reply_text = _("Reply");
		var delete_text = _("Delete");
		
		//rounded userpics
		string rounded = "";
		if(prefs.roundedAvatars)
			rounded = "-webkit-border-radius:5px;";
		
		var h = new HashMap<string, string>();
		h["var"] = "troorl";
		render("", h);
		
		foreach(Status i in friends) {
			//checking for new statuses
			var fresh = "old";
			if(last_focused > 0 && (int)i.created_at.mktime() > last_focused)
				fresh = "fresh";
			
			//making human-readable time/date
			string time = time_to_human_delta(now, i.created_at);
			
			if(i.user_screen_name == prefs.login) { //your own status
				var map = new HashMap<string, string>();
				map["avatar"] = cache.get_or_download(i.user_avatar, Cache.Method.ASYNC, false);
				map["me"] = "me";
				map["id"] = i.id;
				map["time"] = time;
				map["name"] = i.user_name;
				map["content"] = making_links(i.text);
				map["delete_text"] = delete_text;
				content += render(statusMeTemplate, map);
				
			} else {
				var re_icon = "";
				var by_who = "";
				
				if(i.to_user != "") { // in reply to
					string to_user = i.to_user;
					if(to_user == prefs.login)
						to_user = "you";
					by_who = "<a class='by_who' href='http://twitter.com/%s/status/%s'>%s %s</a>".printf(i.to_user, i.to_status_id, _("in reply to"), to_user);
				}
				
				var user_avatar = i.user_avatar;
				var name = i.user_name;
				var screen_name = i.user_screen_name;
				var text = i.text;
				
				if(i.is_retweet) {
					re_icon = "<span class='re'>Rt:</span> ";
					by_who = "<a class='by_who' href='nickto://%s'>by %s</a>".printf(i.user_screen_name, i.user_name);
					name = i.re_user_name;
					screen_name = i.re_user_screen_name;
					user_avatar = i.re_user_avatar;
					text = i.re_text;
				}
				
				var map = new HashMap<string, string>();
				map["avatar"] = cache.get_or_download(user_avatar, Cache.Method.ASYNC, false);
				map["fresh"] = fresh;
				map["id"] = i.id;
				map["re_icon"] = re_icon;
				map["screen_name"] = screen_name;
				map["name"] = name;
				map["time"] = time;
				map["content"] = making_links(text);
				map["bywho"] = by_who;
				map["reply_text"] = reply_text;
				content += render(statusTemplate, map);
			}
		}
		
		var map = new HashMap<string, string>();
		map["bg_color"] = gtkStyle.bg_color;
		map["fg_color"] = gtkStyle.fg_color;
		map["rounded"] = rounded;
		map["lt_color"] = gtkStyle.lt_color;
		map["sl_color"] = gtkStyle.sl_color;
		map["lg_color"] = gtkStyle.lg_color;
		map["main_content"] = content;
		
		return render(mainTemplate, map);
	}
	
	private string render(string text, HashMap<string, string> map) {
		string result = text;
		
		foreach(string key in map.keys) {
			var pat = new Regex("{{" + key + "}}");
			result = pat.replace(result, -1, 0, map[key]);
		}
		
		return result;
	}
	
	private string making_links(string text) {
		string result = text;
		
		//result = urls.replace(text, -1, 0, "<a href='\\0'>\\0</a>");
		
		//I hate glib regex......
		int pos = 0;
		while(true) {
			//url cutting
			MatchInfo match_info;
			bool bingo = urls.match_all_full(text, -1, pos, GLib.RegexMatchFlags.NEWLINE_ANY, out match_info);
			if(bingo) {
				foreach(string s in match_info.fetch_all()) {
					if(s.length > 30) {
						result = result.replace(s, "<a href='%s' title='%s'>%s...</a>".printf(s, s, s.substring(0, 30)));
					} else {
						result = result.replace(s, "<a href='%s'>%s</a>".printf(s, s));
					}
					
					match_info.fetch_pos(0, null, out pos);
					break;
				}
			} else break;
		}
		
		result = nicks.replace(result, -1, 0, "@<a class='re_nick' href='http://twitter.com/\\1'>\\1</a>");
		result = tags.replace(result, -1, 0, "<a class='tags' href='http://twitter.com/#search?q=\\1'>\\1</a>");
		return result;
	}
	
	private string time_to_human_delta(Time now, Time t) {
		var delta = (int)(now.mktime() - t.mktime());
		if(delta < 30)
			return _("a few seconds ago");
		if(delta < 120)
			return _("1 minute ago");
		if(delta < 3600)
			return _("%i minutes ago").printf(delta / 60);
		if(delta < 7200)
			return _("about 1 hour ago");
		if(delta < 86400)
			return _("about %i hours ago").printf(delta / 3600);
		
		return t.format("%k:%M %b %d %Y");
	}
	
	private Time get_current_time() {
		var tval = TimeVal();
		tval.get_current_time();
		return Time.local((time_t)tval.tv_sec);
		//warning("lolo %s", tr.to_string());
	}
	
	public void reload() {
		//load templates
		mainTemplate = loadTemplate(Config.TEMPLATES_PATH + "/main.tpl");
		statusTemplate = loadTemplate(Config.TEMPLATES_PATH + "/status.tpl");
		statusMeTemplate = loadTemplate(Config.TEMPLATES_PATH + "/status_me.tpl");
	}
	
	private string loadTemplate(string path) {
		var file = File.new_for_path(path);
		
		if(!file.query_exists(null)) {
			stderr.printf("File '%s' doesn't exist.\n", file.get_path());
			//return 1
		}
		
		var in_stream = new DataInputStream (file.read(null));
		
		string result = "";
		string tmp = "";
		while((tmp = in_stream.read_line(null, null)) != null)
			result += tmp;
		tmp = null;
		in_stream = null;
		return result;
	}
}