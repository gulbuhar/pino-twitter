/* rest_api_abstract.vala
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
using Soup;
using Auth;
using TimeUtils;
using Xml;

namespace RestAPI {

public class Status : Object {

	public string id;
	public string text;
	public Time created_at = Time();
	public string created_at_s = "";
	public string user_name;
	public string user_screen_name;
	public string user_avatar;
	
	public string re_text = "";
	public string re_user_name;
	public string re_user_screen_name;
	public string re_user_avatar;
	
	public string to_user = "";
	public string to_status_id = "";
	
	public bool is_retweet = false;
	public bool is_favorite = false;
	
	public bool tmp = false;
}

public class FullStatus : Status {
	
	public string followers = "";
	public string friends = "";
	public string statuses = "";
	public string url = "";
	public string desc = "";
	public bool following = false;
	
	public bool done = false;
	
}

public struct AuthData {
	public string login;
	public string password;
	public string service;
} 

public static enum ServiceType {
	TWITTER,
	IDENTICA,
	UNKNOWN
}

errordomain RestError {
	CODE,
	CODE_404
}

errordomain ParseError {
	CODE
}

public static enum TimelineType {
	HOME,
	MENTIONS,
	USER,
	FAVORITES
}

public abstract class RestAPIAbstract : Object {
	
	protected RestUrls urls;
	public Account? account;
	
	private Session? session = null;
	
	public RestAPIAbstract(Account? _account) {
		urls = new RestUrls(ServiceType.UNKNOWN);
		set_auth(_account);
	}
	
	private void select_urls() {
		switch(account.service) {
			case "twitter.com":
				urls.set_prefix(ServiceType.TWITTER);
				break;
			
			case "identi.ca":
				urls.set_prefix(ServiceType.IDENTICA);
				break;
			
			case "other":
				string proxy = "http://api.twitter.com/";
				if(account.proxy != "")
					proxy = account.proxy;
				
				urls.set_prefix(ServiceType.UNKNOWN, proxy);
				break;
			
			default:
				urls.set_prefix(ServiceType.TWITTER);
				break;
		}
	}
	
	public void set_auth(Account? _account) {
		account = _account;
		
		if(account != null)
			select_urls();
	}
	
	public signal void request(string req);
	
	public virtual ArrayList<Status>? get_timeline(int count = 0, FullStatus? fstatus = null,
		string since_id = "", string max_id = "", bool sync = true) throws RestError, ParseError {
		
		return null;
	}
	
	public virtual Status get_status(string id) throws RestError, ParseError {
		return new Status();
	}
	
	public virtual void favorite_create(string id) throws RestError {}
	public virtual void favorite_destroy(string id) throws RestError {}
	
	public virtual void follow_create(string screen_name) throws RestError {}
	public virtual void follow_destroy(string screen_name) throws RestError {}
	
	public virtual void destroy_status(string id) throws RestError {}
	
	protected void reply_tracking(int status_code) throws RestError {
		switch(status_code) {
			case 2:
				throw new RestError.CODE("Connection problems: can't connect to the server.");
			
			case 400:
				throw new RestError.CODE("%d Rate limiting: you have reached the limit requests.".printf(status_code));
			
			case 401:
				throw new RestError.CODE("%d Unauthorized: the request requires user authentication.".printf(status_code));
			
			case 403:
				throw new RestError.CODE("%d Forbidden: the server understood the request, but is refusing to fulfill it.".printf(status_code));
			
			case 404:
				throw new RestError.CODE_404("%d Not Found: The server has not found anything matching the Request-URI.".printf(status_code));
			
			case 407:
				throw new RestError.CODE("%d Proxy Authentication Required: the request requires user authentication.".printf(status_code));
			
			default:
				throw new RestError.CODE("%d Unknown Error".printf(status_code));
		}
	}
	
	protected void no_account() throws RestError {
		throw new RestError.CODE("Account is not found");
	}
	
	public void stop() {
		if(session != null) {
			session.abort();
		}
	}
	
	public string make_request(owned string req_url, string method,
		HashTable<string, string> params = new HashTable<string, string>(str_hash, str_equal),
		bool async = true, int retry = 3) throws RestError {
		
		if(account == null)
			no_account();
		
		if(method == "GET") { //set get-parameters
			string query = "";
			warning(params.size().to_string());
			if(params.size() > 0) {
				query = "?";
				
				int tmp_iter = 0;
				foreach(string key in params.get_keys()) {
					query += Soup.form_encode(key, params.lookup(key));
					
					if(tmp_iter < params.size() - 1)
						query += "&";
					
					tmp_iter++;
				}
			}
			req_url += query;
		}
		
		//send signal about all requests
        request("%s: %s".printf(method, req_url));
        
        //Session session;
        
		if(async)
			session = new SessionAsync();
		else
			session = new SessionSync();
		
        Message message = new Message(method, req_url);
        message.set_http_version(HTTPVersion.1_1);
        
        MessageHeaders headers = new MessageHeaders(MessageHeadersType.MULTIPART);
        headers.append("User-Agent", "%s/%s".printf(Config.APPNAME, Config.APP_VERSION));
        
        message.request_headers = headers;
        
        if(method != "GET") { //set post/delete-parameters
        	string body = form_encode_hash(params);
			message.set_request("application/x-www-form-urlencoded",
				MemoryUse.COPY, body, (int)body.size());
		}
		
		//Basic HTTP authorization
        session.authenticate += (sess, msg, auth, retrying) => {
			if (retrying) return;
			auth.authenticate(account.login, account.password);
		};
		
		int status_code = 0;
		for(int i = 0; i < retry; i++) {
			status_code = (int)session.send_message(message);
			if(status_code == 200 || status_code == 401)
				break;
		}
		
		if(status_code != 200)
			reply_tracking(status_code);
		
		return (string)message.response_body.flatten().data;
	}
	
	/* check user for DM availability */
	public bool check_friendship(string screen_name,
		bool just_friend_check = false) throws RestError {
		
		string req_url = urls.friendship();
		
		var map = new HashTable<string, string>(str_hash, str_equal);
		map.insert("source_screen_name", account.login);
		map.insert("target_screen_name", screen_name);
		warning(req_url);
		string data = make_request(req_url, "GET", map);
		
		return parse_friendship(data, just_friend_check);
	}
	
	private bool parse_friendship(string data, bool just_friend_check = false) {
		bool followed_by = false;
		bool following = false;
		
		Xml.Doc* xmlDoc = Xml.Parser.parse_memory(data, (int)data.size());
		Xml.Node* rootNode = xmlDoc->get_root_element();
		
		Xml.Node* iter;
		for(iter = rootNode->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE)
				continue;
			
			if(iter->name == "target") {
				
				Xml.Node* iter_in;
				for(iter_in = iter->children; iter_in != null; iter_in = iter_in->next) {
					switch(iter_in->name) {
						case "followed_by":
							followed_by = iter_in->get_content().to_bool();
							break;
					
						case "following":
							following = iter_in->get_content().to_bool();
							break;
					}
				}
				delete iter_in;
				break;
			}
			
		} delete iter;
		
		if(just_friend_check && followed_by)
			return true;
		
		if(followed_by && following)
			return true;
		
		return false;
	}
}

}
