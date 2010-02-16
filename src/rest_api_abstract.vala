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

namespace RestAPI {

public class Status : Object {
	public string id;
	public string text;
	public Time created_at = Time();
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
}

public struct AuthData {
	public string login = "";
	public string password = "";
	public string service = "";
} 

errordomain RestError {
	CODE
}

errordomain ParseError {
	CODE
}

public static enum TimelineType {
	HOME,
	MENTIONS
}

public abstract class RestAPIAbstract : Object {
	
	protected IRestUrls urls;
	public Account? account;
	
	public RestAPIAbstract(Account? _account) {
		set_auth(_account);
	}
	
	private IRestUrls select_urls(string service) {
		switch(service) {
			case "twitter.com":
				return new TwitterUrls();
			
			case "identi.ca":
				return new IdenticaUrls();
			
			default:
				return new TwitterUrls();
		}
	}
	
	public void set_auth(Account? _account) {
		account = _account;
		
		if(account != null)
			urls = select_urls(account.service);
	}
	
	public signal void request(string req);
	
	public virtual ArrayList<Status>? get_timeline(int count = 0,
		string since_id = "", string max_id = "") throws RestError, ParseError {
		
		return null;
	}
	
	
	public virtual void destroy_status(string id) throws RestError {}
	
	protected void reply_tracking(int status_code) throws RestError {
		switch(status_code) {
			case 2:
				throw new RestError.CODE("Connection problems: can't connect to the server.");
			
			case 401:
				throw new RestError.CODE("%d Unauthorized: the request requires user authentication.".printf(status_code));
			
			case 403:
				throw new RestError.CODE("%d Forbidden: the server understood the request, but is refusing to fulfill it.".printf(status_code));
			
			case 404:
				throw new RestError.CODE("%d Not Found: The server has not found anything matching the Request-URI.".printf(status_code));
			
			case 407:
				throw new RestError.CODE("%d Proxy Authentication Required: the request requires user authentication.".printf(status_code));
			
			default:
				throw new RestError.CODE("%d Unknown Error".printf(status_code));
		}
	}
	
	protected void no_account() throws RestError {
		throw new RestError.CODE("Account is not found");
	}
	
	public string make_request(owned string req_url, string method,
		HashTable<string, string> params = new HashTable<string, string>(null, null),
		bool async = true, int retry = 3) throws RestError {
		
		if(account == null)
			no_account();
		
		if(method == "GET") { //set get-parameters
			string query = "";
		
			if(params.size() > 0) {
				query = "?";
				
				//Very dirty. HashTable.loockup() doesn't work. Bug?
				int tmp_iter = 0;
				foreach(string key in params.get_keys()) {
					int tmp_iter2 = 0;
					foreach(string val in params.get_values()) {
						if(tmp_iter2 == tmp_iter) {
							query += Soup.form_encode(key, val);
							if(tmp_iter < params.size() - 1)
								query += "&";
							break;
						}
						tmp_iter2++;
					}
					tmp_iter++;
				}
			}
			req_url += query;
		}
		
		//send signal about all requests
        request("%s: %s".printf(method, req_url));
        
        Session session;
        
		if(async)
			session = new SessionAsync();
		else
			session = new SessionSync();
		
        Message message = new Message(method, req_url);
        message.set_http_version (HTTPVersion.1_1);
        
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
}

}
