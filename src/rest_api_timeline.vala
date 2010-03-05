/* rest_api_timeline.vala
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
using Xml;
using Auth;
using TimeUtils;

namespace RestAPI {

public class RestAPITimeline : RestAPIAbstract {
	
	private TimelineType timeline_type;
	
	public RestAPITimeline(Account? _account,
		TimelineType _timeline_type) {
		base(_account);
		this.timeline_type = _timeline_type;
	}
	
	/* destroy status */
	public override void destroy_status(string id) throws RestError {
		string req_url = urls.destroy_status().printf(id);
		make_request(req_url, "DELETE");
	}
	
	/* for timelines (home, mentions, public etc.) */
	public override ArrayList<Status>? get_timeline(int count = 0, FullStatus? fstatus = null,
		string since_id = "", string max_id = "") throws RestError, ParseError {
		
		if(account == null)
			no_account();
		
		string req_url = "";
		
		switch(timeline_type) {
			case TimelineType.HOME:
				req_url = urls.home();
				break;
			case TimelineType.MENTIONS:
				req_url = urls.mentions();
				break;
			case TimelineType.USER:
				req_url = urls.users_timeline().printf(fstatus.user_screen_name);
				break;
		}
		
		var map = new HashTable<string, string>(null, null);
		if(count != 0)
			map.insert("count", count.to_string());
		if(since_id != "")
			map.insert("since_id", since_id);
		if(max_id != "")
			map.insert("max_id", max_id);
		warning(req_url);
		string data = make_request(req_url, "GET", map);
		
		return parse_timeline(data, fstatus);
	}
	
	/* parsing timeline */
	private ArrayList<Status> parse_timeline(string data,
		FullStatus? fstatus) throws ParseError {
		
		Xml.Doc* xmlDoc = Parser.parse_memory(data, (int)data.size());
		Xml.Node* rootNode = xmlDoc->get_root_element();
		
		//changing locale to C
		string currentLocale = GLib.Intl.setlocale(GLib.LocaleCategory.TIME, null);
		GLib.Intl.setlocale(GLib.LocaleCategory.TIME, "C");
		
		ArrayList<Status> lst = new ArrayList<Status>();
		
		for(Xml.Node* iter = rootNode->children; iter != null; iter = iter->next) {
			if(iter->type != ElementType.ELEMENT_NODE)
				continue;
			
			if(iter->name == "status") {
				
				if(iter->children != null) {
		        	Status status = new Status();
		        	Xml.Node *iter_in;
				    
				    for(iter_in = iter->children->next; iter_in != null; iter_in = iter_in->next) {
				    	
				    	if(iter_in->is_text() != 1) {
				    		
				    		switch(iter_in->name) {
				    			case "id":
				    				status.id = iter_in->get_content();
				    				break;
				    			
				    			case "created_at":
				    				status.created_at = str_to_time(iter_in->get_content());
				    				break;
				    			
				    			case "text":
				    				status.text = iter_in->get_content();
				    				break;
				    			
				    			case "in_reply_to_screen_name":
				    				status.to_user = iter_in->get_content();
				    				break;
				    			
				    			case "in_reply_to_status_id":
				    				status.to_status_id = iter_in->get_content();
				    				break;
				    			
				    			case "retweeted_status":
				    				status.is_retweet = true;
				    				
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
				    							if(iter_retweet->get_content().substring(0, 3) != "\n  " ) {
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
										if(fstatus != null && !fstatus.done) { //get full info about this user
											switch(iter_user->name) {
												case "name":
													status.user_name = iter_user->get_content();
													fstatus.user_name = iter_user->get_content();
													break;
											
												case "screen_name":
													warning("This is %s", iter_user->get_content());
													status.user_screen_name = iter_user->get_content();
													fstatus.user_screen_name = iter_user->get_content();
													break;
											
												case "profile_image_url":
													status.user_avatar = iter_user->get_content();
													fstatus.user_avatar = iter_user->get_content();
													break;
												
												case "followers_count":
													fstatus.followers = iter_user->get_content();
													break;
												
												case "friends_count":
													fstatus.friends = iter_user->get_content();
													break;
												
												case "statuses_count":
													fstatus.statuses = iter_user->get_content();
													break;
												
												case "url":
													fstatus.url = iter_user->get_content();
													break;
												
												case "description":
													fstatus.desc = iter_user->get_content();
													break;
											}
										} else {
											switch(iter_user->name) {
												case "name":
													status.user_name = iter_user->get_content();
													break;
											
												case "screen_name":
													status.user_screen_name = iter_user->get_content();
													break;
											
												case "profile_image_url":
													status.user_avatar = iter_user->get_content();
													break;
											}
										}
				    					
				    				}
				    				
				    				if(fstatus != null)
					    				fstatus.done = true;
					    			
				    				delete iter_user;
				    				break;
				    		}
				    	}
				    }
				    delete iter_in;
				    
				    lst.add(status);
				    
				}
		    }
		    delete iter; //memory leak was here >:3
		}
		
		//back to the normal locale
		GLib.Intl.setlocale(GLib.LocaleCategory.TIME, currentLocale);
		return lst;
	}
	
	/* return single status */
	public override Status get_status(string id) throws RestError, ParseError {
		string req_url = urls.status().printf(id);
		string data = make_request(req_url, "GET");
		
		return parse_status(data);
	}
	
	private Status parse_status(string data) throws ParseError {
		Xml.Doc* xmlDoc = Parser.parse_memory(data, (int)data.size());
		Xml.Node* rootNode = xmlDoc->get_root_element();
		
		//changing locale to C
		string currentLocale = GLib.Intl.setlocale(GLib.LocaleCategory.TIME, null);
		GLib.Intl.setlocale(GLib.LocaleCategory.TIME, "C");
		
		Status status = new Status();
		
		for(Xml.Node* iter = rootNode->children; iter != null; iter = iter->next) {
			if(iter->type != ElementType.ELEMENT_NODE)
				continue;
			
			switch(iter->name) {
				case "id":
					status.id = iter->get_content();
    				break;
    			
    			case "created_at":
    				status.created_at = str_to_time(iter->get_content());
    				break;
    			
    			case "text":
    				status.text = iter->get_content();
    				break;
    			
    			case "in_reply_to_screen_name":
    				status.to_user = iter->get_content();
    				break;
    			
    			case "in_reply_to_status_id":
    				status.to_status_id = iter->get_content();
    				break;
    			
    			case "user":
    				Xml.Node *iter_user;
    				
					for(iter_user = iter->children->next; iter_user != null; iter_user = iter_user->next) {
						switch(iter_user->name) {
							case "id":
    							break;
    						
    						case "name":
    							status.user_name = iter_user->get_content();
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
		
		//back to the normal locale
		GLib.Intl.setlocale(GLib.LocaleCategory.TIME, currentLocale);
		
		return status;
	}
}

}
