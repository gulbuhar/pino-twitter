/* template.vala
 *
 * Copyright (C) 2009-2010  troorl
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
using Auth;
using RestAPI;
using TimeUtils;

public class Template : Object {
	
	private Prefs prefs;
	private SystemStyle gtk_style;
	private Cache cache;
	
	private Accounts accounts;
	private string login;
	private string status_url;
	private string search_url;
	private string nick_url;
	
	private string main_template;
	private string status_template;
	private string status_me_template;
	private string status_direct_template;
	
	private Regex nicks;
	private Regex tags;
	private Regex urls;
	private Regex clear_notice;
	
	public signal void emit_for_refresh();
	
	public Template(Prefs _prefs, Accounts _accounts, SystemStyle _gtk_style, Cache _cache) {
		prefs = _prefs;
		accounts = _accounts;
		gtk_style = _gtk_style;
		cache = _cache;
		reload();
		
		//compile regex
		nicks = new Regex("@([A-Za-z0-9_]+)");
		tags = new Regex("((^|\\s)\\#[A-Za-z0-9_]+)");
		urls = new Regex("((http|https|ftp)://([\\S]+))"); //need something better
		
		// characters must be cleared to know direction of text
		clear_notice = new Regex("[: \n\t\r♻♺]+|@[^ ]+");
		
		prefs.roundedAvatarsChanged.connect(() => emit_for_refresh());
		prefs.opacityTweetsChanged.connect(() => emit_for_refresh());
		prefs.rtlChanged.connect(() => emit_for_refresh());
		prefs.fullNamesChanged.connect(() => emit_for_refresh());
		prefs.fontChanged.connect(() => emit_for_refresh());
	}
	
	private void login_changed() {
		var acc = accounts.get_current_account();
		
		if(acc != null) {
			login = acc.login;
			
			switch(acc.service) {
				case "twitter.com":
					status_url = "http://twitter.com/%s/status/%s";
					search_url = "http://twitter.com/#search?q=";
					nick_url = "http://twitter.com/";
					break;
				
				case "identi.ca":
					status_url = "http://identi.ca/notice/%s";
					search_url = "http://identi.ca/search/notice?q=";
					nick_url = "http://identi.ca/";
					break;
			}
		}
	}
	
	public void refresh_gtk_style(SystemStyle _gtk_style) {
		gtk_style = _gtk_style;
		emit_for_refresh();
	}
	
	private string generate(string content) {
		//rounded userpics
		string rounded_str = "";
		if(prefs.roundedAvatars)
			rounded_str = "-webkit-border-radius:5px;";
		
		var map = new HashMap<string, string>();
		map["bg_color"] = gtk_style.bg_color;
		map["fg_color"] = gtk_style.fg_color;
		map["rounded"] = rounded_str;
		map["lt_color"] = gtk_style.lt_color;
		map["sl_color"] = gtk_style.sl_color;
		map["lg_color"] = gtk_style.lg_color;
		map["dr_color"] = gtk_style.dr_color;
		map["tweets_opacity"] = prefs.opacityTweets;
		map["font_size"] = prefs.deFontSize.to_string();
		map["font_size_small"] = (prefs.deFontSize - 1).to_string();
		map["fresh_color"] = prefs.freshColor;
		map["font_name"] = prefs.deFontName;
		map["main_content"] = content;
		
		return render(main_template, map);
	}
	
	/* render start screen */
	public string generate_message(string message) {
		string content = "<h2>%s</h2>".printf(message);
		
		return generate(content);
	}
	
	/* render direct inbox */
	public string generate_direct(Gee.ArrayList<Status> friends, int last_focused) {
		login_changed();
		
		string content = "";
		
		var now = get_current_time();
		
		var reply_text = _("Reply");
		var delete_text = _("Delete");
		var dm_text = _("Direct message");
		
		//rounded userpics
		string rounded_str = "";
		if(prefs.roundedAvatars)
			rounded_str = "-webkit-border-radius:5px;";
		
		foreach(Status i in friends) {
			//checking for new statuses
			var fresh = "old";
			if(last_focused > 0 && (int)i.created_at.mktime() > last_focused)
				fresh = "fresh";
			
			//making human-readable time/date
			string time = time_to_human_delta(now, i.created_at);
			
			var user_avatar = i.user_avatar;
			var name = i.user_screen_name;
			var screen_name = i.user_screen_name;
			var text = i.text;
			
			var map = new HashMap<string, string>();
			map["avatar"] = cache.get_or_download(user_avatar, Cache.Method.ASYNC, false);
			map["fresh"] = fresh;
			map["id"] = i.id;
			map["screen_name"] = screen_name;
			
			if(prefs.fullNames)
				map["name"] = name;
			else
				map["name"] = screen_name;
			
			map["time"] = time;
			map["content"] = making_links(text);
			
			if(prefs.rtlSupport && is_rtl(clear_notice.replace(i.text, -1, 0, "")))
				map["rtl_class"] = "rtl-notice";
			else
				map["rtl_class"] = "";
			
			map["delete_text"] = delete_text;
			map["dm_text"] = dm_text;
			map["delete"] = Config.DELETE_PATH;
			map["direct_reply"] = Config.DIRECT_REPLY_PATH;
			content += render(status_direct_template, map);
		}
		
		return generate(content);
	}
	
	/* render timeline, mentions */
	public string generate_timeline(Gee.ArrayList<Status> friends, int last_focused) {
		login_changed();
		
		string content = "";
		
		var now = get_current_time();
		
		var reply_text = _("Reply");
		var delete_text = _("Delete");
		var retweet_text = _("Retweet");
		var dm_text = _("Direct message");
		
		//rounded userpics
		string rounded_str = "";
		if(prefs.roundedAvatars)
			rounded_str = "-webkit-border-radius:5px;";
		
		foreach(Status i in friends) {
			//checking for new statuses
			var fresh = "old";
			if(last_focused > 0 && (int)i.created_at.mktime() > last_focused)
				fresh = "fresh";
			
			//making human-readable time/date
			string time = time_to_human_delta(now, i.created_at);
			
			var by_who = "";
				
			if(i.to_user != "") { // in reply to
				string to_user = i.to_user;
				if(to_user == login)
					to_user = _("you");
				
				by_who = "<a class='by_who' href='showtree://%s'>%s %s</a>".printf(i.id, _("in reply to"), to_user);
			}
			
			if(i.user_screen_name == login) { //your own status
				var map = new HashMap<string, string>();
				map["avatar"] = cache.get_or_download(i.user_avatar, Cache.Method.ASYNC, false);
				map["me"] = "me";
				map["id"] = i.id;
				map["time"] = time;
				map["by_who"] = by_who;
				
				if(prefs.fullNames)
					map["name"] = i.user_name;
				else
					map["name"] = i.user_screen_name;
			
				map["content"] = making_links(i.text);

				if(prefs.rtlSupport && is_rtl(clear_notice.replace(i.text, -1, 0, "")))
					map["rtl_class"] = "rtl-notice";
				else
					map["rtl_class"] = "";
				
				map["delete_text"] = delete_text;
				map["delete"] = Config.DELETE_PATH;
				content += render(status_me_template, map);
				
			} else {
				var re_icon = "";
				
				var user_avatar = i.user_avatar;
				var name = i.user_name;
				var screen_name = i.user_screen_name;
				var text = i.text;
				
				if(i.is_retweet) {
					re_icon = "<span class='re'>Rt:</span> ";
					by_who = "<a class='by_who' href='nickto://%s'>by %s</a>".printf(i.user_screen_name, i.user_screen_name);
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
				
				if(prefs.fullNames)
					map["name"] = name;
				else
					map["name"] = screen_name;
			
				map["time"] = time;
				map["content"] = making_links(text);
				
				if(prefs.rtlSupport && is_rtl(clear_notice.replace(i.text, -1, 0, "")))
					map["rtl_class"] = "rtl-notice";
				else
					map["rtl_class"] = "";
				
				map["by_who"] = by_who;
				map["retweet_text"] = retweet_text;
				map["reply_text"] = reply_text;
				map["direct_reply"] = Config.DIRECT_REPLY_PATH;
				map["dm_text"] = dm_text;
				map["reply"] = Config.REPLY_PATH;
				map["re_tweet"] = Config.RETWEET_PATH;
				content += render(status_template, map);
			}
		}
		
		return generate(content);
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
		
		result = nicks.replace(result, -1, 0, "@<a class='re_nick' href='%s\\1'>\\1</a>".printf(nick_url));
		result = tags.replace(result, -1, 0, "<a class='tags' href='%s\\1'>\\1</a>".printf(search_url));
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
	
	public void reload() {
		//load templates
		main_template = load_template(Config.TEMPLATES_PATH + "/main.tpl");
		status_template = load_template(Config.TEMPLATES_PATH + "/status.tpl");
		status_me_template = load_template(Config.TEMPLATES_PATH + "/status_me.tpl");
		status_direct_template = load_template(Config.TEMPLATES_PATH + "/status_direct.tpl");
	}
	
	private string load_template(string path) {
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
	
	/* Right-to-left languages detection by Behrooz Shabani <everplays@gmail.com> */
	private bool is_rtl(string inStr){
		unichar cc = inStr[0]; // first character code
		if(cc>=1536 && cc<=1791) // arabic, persian, ...
			return true;
		if(cc>=65136 && cc<=65279) // arabic peresent 2
			return true;
		if(cc>=64336 && cc<=65023) // arabic peresent 1
			return true;
		if(cc>=1424 && cc<=1535) // hebrew
			return true;
		if(cc>=64256 && cc<=64335) // hebrew peresent
			return true;
		if(cc>=1792 && cc<=1871) // Syriac
			return true;
		if(cc>=1920 && cc<=1983) // Thaana
			return true;
		if(cc>=1984 && cc<=2047) // NKo
			return true;
		if(cc>=11568 && cc<=11647) // Tifinagh
			return true;
		return false;
	}
}
