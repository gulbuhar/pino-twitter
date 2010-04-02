/* url_short.vala
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

using Soup;
using Gee;
using RestAPI;

public class Position : Object {
	public int start;
	public int end;
	
	public Position(int _start, int _end) {
		start = _start;
		end = _end;
	}
}

public class UrlShort : Object {
	
	Prefs prefs;
	RestAPIRe api;
	
	private Regex urls;
	
	public UrlShort(Prefs _prefs, RestAPIRe _api) {
		prefs = _prefs;
		api = _api;
		
		urls = new Regex("((http|https|ftp)://([\\S]+)\\.([\\S]+))");
	}
	
	public string shortit(owned string text) {
		ArrayList<string> urls = find_urls(text);
		if(urls.size == 0)
			return text;
		
		foreach(string url in urls) {
			warning(url);
			try {
				string new_url = "";
				
				switch(prefs.urlShorten) {
					case "goo.gl":
						new_url = shorter_google(url);
						break;
					
					case "is.gd":
						new_url = shorter_isgd(url);
						break;
					
					case "ur1.ca":
						new_url = shorter_ur1(url);
						break;
				}
				
				warning(new_url);
				
				if(new_url.length > 0)
					text = text.replace(url, new_url);
				
			} catch(RestError e) {
				warning(e.message);
			}
		}
		
		return text;
	}
	
	public ArrayList<string> find_urls(owned string text, bool len = true) {
		ArrayList<string> lst = new ArrayList<string>();
		int pos = 0;
		
		while(true) {
			MatchInfo match_info;
			bool bingo = urls.match_all_full(text, -1, pos, GLib.RegexMatchFlags.NEWLINE_ANY, out match_info);
			
			if(bingo) {
				foreach(string s in match_info.fetch_all()) {
					if(len) {
						if(s.length > 18)
							lst.add(s);
					} else {
						lst.add(s);
					}
					
					match_info.fetch_pos(0, null, out pos);
					break;
				}
			} else break;
		}
		
		return lst;
	}
	
	/* shorten with http://goo.gl */
	private string shorter_google(string url) throws RestError {
		var map = new HashTable<string, string>(str_hash, str_equal);
		map.insert("url", url);
		
		string req_url = "http://ggl-shortener.appspot.com/";
		
		string data = api.make_request(req_url, "GET", map);
		
		return data.split("\"")[3];
	}
	
	/* shorten with http://is.gd */
	private string shorter_isgd(string url) throws RestError {
		var map = new HashTable<string, string>(str_hash, str_equal);
		map.insert("longurl", url);
		
		string req_url = "http://is.gd/api.php";
		
		return api.make_request(req_url, "GET", map);
	}
	
	/* shorten with http://ur1.ca via Behrooz Shabani <everplays@gmail.com> */
	private string shorter_ur1(string url) throws RestError {
		var map = new HashTable<string, string>(str_hash, str_equal);
		map.insert("longurl", url);
		map.insert("submit", "Make it an ur1!");

		string response = api.make_request("http://ur1.ca/", "POST", map);
		MatchInfo ur1_match;
		var ur1_regex = new Regex("Your ur1 is: <a href=\"([^\"]+)\">");
		if(ur1_regex.match(response, 0, out ur1_match))
			return (string) ur1_match.fetch(1);
		else
			return url;
	}
}
