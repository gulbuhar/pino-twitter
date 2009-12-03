using Xml;
using Gee;
using Soup;

public class Status {
		
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
	
	public bool is_retweet = false;
	public bool is_new = false;
	public bool unreaded = false;
}

public class TwitterInterface : Object {
	
	public enum Reply {
		ERROR_TIMEOUT, ERROR_401, ERROR_UNKNOWN, OK
	}
	
	public enum SyncMethod {
		FRIENDS, MENTIONS
	}
	
	private Gee.ArrayList<Status> _friends = new Gee.ArrayList<Status>();
	public Gee.ArrayList<Status> friends {
		get{ return _friends; }	
	}
	
	private Gee.ArrayList<Status> _mentions = new Gee.ArrayList<Status>();
	public Gee.ArrayList<Status> mentions {
		get{ return _mentions; }	
	}
	
	private string login;
	private string password;
	
	private const string friendsUrl = "http://api.twitter.com/1/statuses/home_timeline.xml";
	private const string statusUpdateUrl = "http://twitter.com/statuses/update.xml";
	private const string destroyStatusUrl = "http://twitter.com/statuses/destroy/%s.xml";
	private const string mentionsUrl = "http://twitter.com/statuses/mentions.xml";
	
	public signal void updating();
	public signal void send_status();
	public signal void updated();
	public signal void destroying_status();
	
	public TwitterInterface(){}
	
	public TwitterInterface.with_auth(string _login, string _password) {
		set_auth(_login, _password);
	}
	
	public void set_auth(string _login, string _password) {
		login = _login;
		password = _password;
	}
	
	public Reply sync_friends(int last_time, int last_focused) {
		return sync(last_time, last_focused, SyncMethod.FRIENDS);
	}
	
	public Reply sync_mentions(int last_time, int last_focused) {
		return sync(last_time, last_focused, SyncMethod.MENTIONS);
	}
	
	public Reply sync(int last_time, int last_focused, SyncMethod type) {
		updating();
		
		string Uri = null;
		Gee.ArrayList<Status> lst = null;
		
		if(type == SyncMethod.FRIENDS) {
			Uri = friendsUrl;
			lst = friends;
		}
		
		if(type == SyncMethod.MENTIONS) {
			Uri = mentionsUrl;
			lst = mentions;
		}
		
		var session = new Soup.SessionAsync();
		session.timeout = 10;
        var message = new Soup.Message("GET", Uri);

        /* see if we need HTTP auth */
        session.authenticate += (sess, msg, auth, retrying) => {
        	if (retrying) return;
        	//stdout.printf ("Authentication required\n");
        	auth.authenticate(login, password);
        };
		//Posix.sleep(10);
        /* send a sync request */
        //warning("STATUS: %d", (int)status);
        switch(session.send_message(message)) {
        	case 401:
        		return Reply.ERROR_401;
        	case 2:
        		return Reply.ERROR_TIMEOUT;
        	case 200:
				parse_xml(message.response_body.data, last_time, last_focused, lst);
				updated();
        		return Reply.OK;
        	default:
        		return Reply.ERROR_UNKNOWN;
        }
		//return Reply.OK;
	}
	
	public Reply updateStatus(string status, string reply_id = "") {
		send_status();
		
		var session = new Soup.SessionAsync();
		var message = new Soup.Message("POST", statusUpdateUrl);
		
		string req_body;
		if(reply_id == "")
			req_body = Soup.form_encode("status", status);
		else
			req_body = Soup.form_encode("status", status, "in_reply_to_status_id", reply_id);
		
		message.set_request("application/x-www-form-urlencoded",
			Soup.MemoryUse.COPY, req_body, req_body.length);
		
		session.authenticate += (sess, msg, auth, retrying) => {
        	if (retrying) return;
        	//stdout.printf ("Authentication required\n");
        	auth.authenticate(login, password);
        };
        
        //warning("STATUS: %d", (int)status);
        switch(session.send_message(message)) {
        	case 401:
        		return Reply.ERROR_401;
        	case 2:
        		return Reply.ERROR_TIMEOUT;
        	case 200:
        		return Reply.OK;
        	default:
        		return Reply.ERROR_UNKNOWN;
        }
	}
	
	public Reply destroyStatus(string status_id) {
		destroying_status();
		
		var session = new Soup.SessionAsync();
		var message = new Soup.Message("DELETE", destroyStatusUrl.printf(status_id));
		
		/*string req_body = Soup.form_encode("status", status, "user", name);
		message.set_request("application/x-www-form-urlencoded",
			Soup.MemoryUse.COPY, req_body, req_body.length);
		*/
		session.authenticate += (sess, msg, auth, retrying) => {
        	if (retrying) return;
        	//stdout.printf ("Authentication required\n");
        	auth.authenticate(login, password);
        };
        
        //warning("STATUS: %d", (int)status);
        switch(session.send_message(message)) {
        	case 401:
        		return Reply.ERROR_401;
        	case 2:
        		return Reply.ERROR_TIMEOUT;
        	case 200:
        		return Reply.OK;
        	default:
        		return Reply.ERROR_UNKNOWN;
        }
	}
	
	private int tz_delta(Time t) {
		//getting a time zone delta
		//VERY DIRTY!!!
		//var t = Time().mktime();
		//var time = Time.local(t);
		string sdelta = t.format("%z");
		
		return sdelta.to_int() / 100;
	}
	
	private void parse_xml(string data, int last_time, int last_focused,
		Gee.ArrayList<Status> lst) {	
		Xml.Doc* xmlDoc = Parser.parse_memory(data, (int)data.length);
		Xml.Node* rootNode = xmlDoc->get_root_element();
		
		//changing locale to C
		string currentLocale = GLib.Intl.setlocale(GLib.LocaleCategory.TIME, null);
		GLib.Intl.setlocale(GLib.LocaleCategory.TIME, "C");
		
		lst.clear();
		
		for(Xml.Node* iter = rootNode->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE)
                continue;
            
            if(iter->name == "status") {
		        
		        if(iter->children != null) {
		        	var status = new Status();
		        	Xml.Node *iter_in;
				    
				    for(iter_in = iter->children->next; iter_in != null; iter_in = iter_in->next) {
				    	
				    	if(iter_in->is_text() != 1) {
				    		//stdout.printf("%s - %s\n", iter_in->name, iter_in->get_content());
				    		
				    		switch(iter_in->name) {
				    			case "id":
				    				status.id = iter_in->get_content();
				    				//warning("ID: %s", status.id);
				    				break;
				    			
				    			case "created_at":
				    				var tmpTime = Time();
				    				tmpTime.strptime(iter_in->get_content(), "%a %b %d %T +0000 %Y");
				    				var tt = tmpTime.mktime();
				    				var tmp = Time.local(tt);
				    				int delta = tz_delta(tmp);
				    				int int_t = (int)tt + delta * 3600;
				    				
				    				status.created_at = Time.local((time_t)int_t);
				    				break;
				    			
				    			case "text":
				    				status.text = iter_in->get_content();
				    				break;
				    			
				    			case "retweeted_status":
				    				status.is_retweet = true;
				    				if(status.is_retweet)
				    					warning("Holy shit! This is retweet!");
				    				
				    				Xml.Node *iter_retweet;
				    				
				    				for(iter_retweet = iter_in->children->next; iter_retweet != null; iter_retweet = iter_retweet->next) {
				    					switch(iter_retweet->name) {
				    						case "user":
				    							Xml.Node *iter_re_user;
				    							
				    							for(iter_re_user = iter_retweet->children->next; iter_re_user != null; iter_re_user = iter_re_user->next) {
				    								switch(iter_re_user->name) {
				    									case "name":
				    										status.re_user_name = iter_re_user->get_content();
				    										break;
				    									
				    									case "screen_name":
				    										status.re_user_screen_name = iter_re_user->get_content();
				    										break;
				    									
				    									case "profile_image_url":
				    										status.re_user_avatar = iter_re_user->get_content();
				    										break;
				    								}
				    							}
				    							delete iter_re_user;
				    							break;
				    						
				    						case "text":
				    							//warning("LOLO: %s", iter_retweet->get_content());
				    							if(iter_retweet->get_content().substring(0, 3) != "\n  " ) {
				    								warning("LOLO: %s", iter_retweet->get_content());
				    								status.re_text = iter_retweet->get_content();
				    							}
				    							break;
				    					}
				    				}
				    				
				    				delete iter_retweet;
				    				break;
				    			
				    			case "user":
				    				Xml.Node *iter_user;
				    				
				    				for(iter_user = iter_in->children->next; iter_user != null; iter_user = iter_user->next) {
				    					switch(iter_user->name) {
				    						case "id":
				    							break;
				    						
				    						case "name":
				    							status.user_name = iter_user->get_content();
				    							//stdout.printf(iter_user->get_content() + "\n");
				    							break;
				    						
				    						case "screen_name":
				    							status.user_screen_name = iter_user->get_content();
				    							break;
				    						
				    						case "profile_image_url":
				    							status.user_avatar = iter_user->get_content();
				    							break;
				    					}
				    				}
				    				delete iter_user;
				    				break;
				    		}
				    	}
				    }
				    delete iter_in;
				    //checking for new status
				    if(last_time > 0) {
				    	//var last_status = _friends.get(0);
				    	if((int)status.created_at.mktime() > last_time) {
				    		status.is_new = true;
				    	}
				    }
				    
				    if(last_focused > 0) {
				    	
				    	if((int)status.created_at.mktime() > last_focused) {
				    		status.unreaded = true;
				    	}
				    }
				    
				    lst.add(status);
				}
		    }
		    delete iter; //memory leak was here >:3
		}
		
		//back to normal locale
		GLib.Intl.setlocale(GLib.LocaleCategory.TIME, currentLocale);
		//delete rootNode;
		//_friends.clear();
		//_friends = null;
		//_friends = tmpList;
	}
}