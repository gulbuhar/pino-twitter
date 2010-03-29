/* timeline_list.vala
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

using Gtk;
using Auth;
using RestAPI;
using WebKit;
using Gee;

/* for home timeline, mentions, public timeline, user's timeline */
public class TimelineList : TimelineListAbstract {
	
	public Icon icon_fresh;
	
	//focus of the main window
	protected bool _parent_focus = false;
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
	public signal void deleted(string message);
	
	public TimelineList(Window _parent, Accounts _accounts, TimelineType timeline_type,
		Template _template, int __items_count = 20, Icon? _icon = null,
		Icon? _icon_fresh = null, string fname = "", string icon_name = "",
		string icon_desc = "", bool _active = false) {
		
		base(_parent, _accounts, timeline_type, _template, __items_count, 
			_icon, fname, icon_name, icon_desc, _active);
		
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
	public override ArrayList<Status>? update() {
		ArrayList<Status> result = null;
		string since_id = "";
		bool first_time = true;
		
		//clearing temporary statuses
		for(int i = 0; i < lst.size; i++) {
			if(lst.get(i).tmp) {
				lst.remove_at(i);
				i--;
			}
		}
		
		if(lst.size > 0) {
			since_id = lst.get(0).id;
			first_time = false;
		}
		
		try {
			result = api.get_timeline(_items_count, null, since_id);
		} catch(RestError e) {
			updating_error(e.message);
			return result;
		}
		
		if(result.size > 0) { //if we got some statuses
			if((!_parent_focus || !act.active) && lst.size > 0) { //if this list is not visible and we have updates
				
				have_fresh = true;
			}
			
			if(lst.size == 0) {
				lst.add_all(result);
			} else {
				int i = 0;
				foreach(Status status in result) { //insert statuses at the start of the list
					lst.insert(i, status);
					i++;
				}
			}
		}
		
		if(!parent_focus) //delete only if main window out of focus
			delete_extra();
		
		warning("SIZE: %d", lst.size);
		
		refresh();
		
		if((act.active && _parent_focus) || last_focused == 0) {
			if(lst.size > 0)
				last_focused = (int)lst.get(0).created_at.mktime();
		}
		
		finish_update(); //send signal
		
		if(first_time)
			result.clear();
		
		return result;
	}
	
	/* insert new status */
	public void insert_status(Status status) {
		lst.insert(0, status);
		//tmp_lst.add(status);
		//delete_extra();
		
		//last_focused = (int)lst.get(0).created_at.mktime();
		
		refresh();
	}
	
	/* delete status with some id */
	protected override void destroy_status(string id) {
		try {
			api.destroy_status(id);
		} catch(RestError e) {
			warning(e.message);
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
		
		deleted(_("Your status has been deleted successfully")); //signal
	}
	
	/* get older statuses */
	protected override void get_older() {
		if(lst.size < 1)
			return;
		
		more.set_enabled(false);
		
		ArrayList<RestAPI.Status> result;
		string max_id = lst.get(lst.size - 1).id;
		
		try {
			result = api.get_timeline(_items_count, null, "", max_id);
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
		
		finish_update(); //send signal
		
		more.set_enabled(true);
		
		refresh();
	}
	
	/** add/remove to favorites */
	private override void favorited(string id) {
		Status? status = null;
		
		foreach(Status s in lst) {
			if(s.id == id) {
				status = s;
				break;
			}
		}
		
		if(status == null)
			return;
		
		try {
			if(!status.is_favorite) //add to favorites
				api.favorite_create(id);
			else
				api.favorite_destroy(id);
		} catch(RestError e) {
			updating_error(e.message);
			return;
		}
		
		status.is_favorite = !status.is_favorite;
		
		string img_path;
		if(status.is_favorite) {
			img_path = Config.FAVORITE_PATH;
			deleted(_("Message was added to favorites")); //signal
		}
		else {
			img_path = Config.FAVORITE_NO_PATH;
			deleted(_("Message was removed from favorites")); //signal
		}
		
		string script = """var m = document.getElementById('fav_%s');
			m.src = '%s';""".printf(status.id, img_path);
		view.execute_script(script);
		
		warning("ok");
	}
}
