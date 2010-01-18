using Gtk;
using RestAPI;
using WebKit;
using Gee;

/* for home timeline, mentions, public timeline, user's timeline */
public class TimelineList : ListAbstract {
	
	public TimelineList(AuthData auth_data, TimelineType timeline_type,
		IRestUrls urls, Template _template, int __items_count) {
		
		base(auth_data, timeline_type, urls, _template, __items_count);
	}
	
	/* get new statuses and update the list */
	public void update() {
		ArrayList<RestAPI.Status> result;
		string since_id = "";
		bool first_time = true;
		
		if(lst.size > 0)
			since_id = lst.get(0).id;
		
		try {
			result = api.get_timeline(_items_count, since_id);
		} catch(RestError e) {
			updating_error(e.message);
			return;
		}
		
		if(result.size > 0) { //if we get some statuses
			if(lst.size == 0) {
				lst.add_all(result);
			} else {
				int i = 0;
				foreach(RestAPI.Status status in result) { //insert statuses at the start of the list
					lst.insert(i, status);
					i++;
				}
				
				while(lst.size > _items_count) //removing extra statuses 
					lst.remove_at(lst.size - 1);
			}
		}
		
		if(focused || last_focused == 0) {
			if(lst.size > 0)
				last_focused = (int)lst.get(0).created_at.mktime();
		}
		warning("SIZE: %d", lst.size);
		update_content();
	}
}