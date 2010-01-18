using Gee;
using Soup;

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
	public AuthData auth_data;
	
	public RestAPIAbstract(IRestUrls _urls, AuthData _auth_data) {
		this.urls = _urls;
		this.auth_data = _auth_data;
	}
	
	public void set_auth(AuthData _auth_data) {
		auth_data = _auth_data;
	}
	
	public abstract ArrayList<Status> get_timeline(int count = 20,
		string since_id = "") throws RestError, ParseError;
	
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
				throw new RestError.CODE("%d Unknown Error");
		}
	}
	
	protected string make_request(owned string req_url, string method,
		HashTable<string, string> params = new HashTable<string, string>(null, null),
		int retry = 3) throws RestError {
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
							query += Soup.form_encode(key, val) + "&";
							break;
						}
						tmp_iter2++;
					}
					tmp_iter++;
				}
			}
			req_url += query;
		}
		
        warning("%s: %s", method, req_url);
        SessionAsync session = new SessionAsync();
        Message message = new Message(method, req_url);
        message.set_http_version (HTTPVersion.1_1);
        
        if(method != "GET") { //set post/delete-parameters
        	string body = form_encode_hash(params);
			message.set_request("application/x-www-form-urlencoded",
				MemoryUse.COPY, body, (int)body.size());
		}
		
		//Basic HTTP authorization
        session.authenticate += (sess, msg, auth, retrying) => {
			if (retrying) return;
			auth.authenticate(auth_data.login, auth_data.password);
		};
		
		int status_code = 0;
		for(int i = 0; i < 3; i++) {
			status_code = (int)session.send_message(message);
			if(status_code == 200)
				break;
		}
		
		if(status_code != 200)
			reply_tracking(status_code);
		
		return message.response_body.data;
	}
	
	protected int tz_delta(Time t) {
		string sdelta = t.format("%z");
		
		return sdelta.to_int() / 100;
	}
}

}