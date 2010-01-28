using Gtk;
using RestAPI;
using WebKit;
using Gee;

/* for home timeline, mentions, public timeline, user's timeline */
public class TimelineList : TimelineListAbstract {
	
	public Icon icon_fresh;
	
	//focus of the main window
	protected bool _parent_focus = true;
	public override bool parent_focus {
		get { return _parent_focus; }
		set {
			_parent_focus = value;
			if(_parent_focus && act.active) {
				have_fresh = false;
				
				if(lst.size > 0)
					last_focused = (int)lst.get(0).created_at.mktime();
			}
			
			if(!value)
				more.hide();
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
	
	public TimelineList(Window _parent, AuthData auth_data, TimelineType timeline_type,
		IRestUrls urls, Template _template, int __items_count, Icon _icon,
		Icon _icon_fresh, string fname, string icon_name, string icon_desc,
		bool _active = false) {
		
		base(_parent, auth_data, timeline_type, urls, _template, __items_count, 
			_icon, fname, icon_name, icon_desc, _active);
		
		icon_fresh = _icon_fresh;
	}
	
	public void set_auth(AuthData auth_data) {
		api.set_auth(auth_data);
		
		lst.clear();
		last_focused = 0;
		update();
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
			}
		}
		
		delete_extra();
		warning("SIZE: %d", lst.size);
		
		refresh();
		
		if((act.active && _parent_focus) || last_focused == 0) {
			if(lst.size > 0)
				last_focused = (int)lst.get(0).created_at.mktime();
		}
		
		finish_update(); //send signal
	}
	
	/* insert new status */
	public void insert_status(Status status) {
		lst.insert(0, status);
		delete_extra();
		
		last_focused = (int)lst.get(0).created_at.mktime();
		
		refresh();
	}
	
	/* delete status with some id */
	protected override void destroy_status(string id) {
		try {
			api.destroy_status(id);
		} catch(RestError e) {
			updating_error(e.message);
			return;
		}
		
		//delete status from the list
		foreach(Status status in lst) {
			if(status.id == id) {
				lst.remove(status);
				break;
			}
		}
		
		last_focused = (int)lst.get(0).created_at.mktime();
		
		refresh();
	}
	
	/* refresh timeline */
	public override void refresh() {
		if(lst.size == 0)
			update_content(template.generate_message(_("Empty")));
		else
			update_content(template.generate_timeline(lst, last_focused));
	}
	
	/* get older statuses */
	protected override void get_older() {
		if(lst.size < 1)
			return;
		
		more.set_enabled(false);
		
		ArrayList<RestAPI.Status> result;
		string max_id = lst.get(lst.size - 1).id;
		
		try {
			result = api.get_timeline(_items_count, "", max_id);
		} catch(RestError e) {
			more.set_enabled(true);
			updating_error(e.message);
			return;
		}
		
		if(result.size < 2) {
			more.set_enabled(true);
			return;
		}
		
		lst.add_all(result.slice(1, result.size -1));
		refresh();
		finish_update(); //send signal
		
		more.set_enabled(true);
	}
}
