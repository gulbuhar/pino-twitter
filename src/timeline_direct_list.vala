using Gee;
using RestAPI;

public class TimelineDirectList : TimelineList {
	
	public TimelineDirectList(AuthData auth_data, IRestUrls urls,
		Template _template, int __items_count, Icon _icon, Icon _icon_fresh,
		string fname, string icon_name, string icon_desc, bool _active = false) {
		
		base(auth_data, TimelineType.HOME, urls, _template, __items_count, _icon,
			_icon_fresh, fname, icon_name, icon_desc, _active);
		
		api = new RestAPIDirect(urls, auth_data);
	}
	
	/* get new direct messages and update the list */
	public override void update() {
		ArrayList<RestAPI.Status> result;
		string since_id = "";
		bool first_time = true;
		
		if(lst.size > 0)
			since_id = lst.get(0).id;
		
		try {
			result = api.get_direct(_items_count, since_id);
		} catch(RestError e) {
			updating_error(e.message);
			return;
		}
		
		if(result.size > 0) { //if we get some statuses
			if((!_parent_focus || !act.active) && lst.size > 0) { //if this list is not visible and we have updates
				
				have_fresh = true;
			}
			
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
		warning("SIZE: %d", lst.size);
		
		update_content();
		
		if((act.active && _parent_focus) || last_focused == 0) {
			if(lst.size > 0)
				last_focused = (int)lst.get(0).created_at.mktime();
		}
	}
}
