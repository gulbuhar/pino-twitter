using Gtk;
using RestAPI;
using WebKit;
using Gee;

/* for home timeline, mentions, public timeline, user's timeline */
public class TimelineList : TimelineListAbstract {
	
	public Icon icon_fresh;
	
	//focus of the main window
	protected bool _parent_focus = true;
	public bool parent_focus {
		get { return _parent_focus; }
		set {
			_parent_focus = value;
			if(_parent_focus && act.active) {
				have_fresh = false;
				
				if(lst.size > 0)
					last_focused = (int)lst.get(0).created_at.mktime();
			}
		}
	}
	
	private bool _have_fresh = false;
	public bool have_fresh {
		get { return _have_fresh; }
		set {
			_have_fresh = value;
			if(_have_fresh) {
				act.set_gicon(icon_fresh);
				fresh();
			} else {
				act.set_gicon(icon);
				no_fresh();
			}
		}
	} 
	
	public signal void fresh();
	public signal void no_fresh();
	
	public TimelineList(AuthData auth_data, TimelineType timeline_type,
		IRestUrls urls, Template _template, int __items_count, Icon _icon,
		Icon _icon_fresh, string fname, string icon_name, string icon_desc,
		bool _active = false) {
		
		base(auth_data, timeline_type, urls, _template, __items_count, _icon,
		fname, icon_name, icon_desc, _active);
		
		icon_fresh = _icon_fresh;
	}
	
	public override void show_smart() {
		show();
		
		if(lst.size > 0) {
			last_focused = (int)lst.get(0).created_at.mktime();
			have_fresh = false;
		}
		
		act.set_gicon(icon);
	}
	
	/* get new statuses and update the list */
	public virtual void update() {
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
