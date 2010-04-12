/* timeline_direct_list.vala
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
using Auth;
using RestAPI;
using Gtk;

public class TimelineDirectList : TimelineList {
	
	public TimelineDirectList(Window _parent, Accounts _accounts,
		Template _template, int __items_count, Icon? _icon, Icon? _icon_fresh,
		string fname, string icon_name, string icon_desc, bool _active = false) {
		
		base(_parent, _accounts, TimelineType.HOME, _template, __items_count,
			_icon, _icon_fresh, fname, icon_name, icon_desc, _active);
		
		var acc = accounts.get_current_account();
		api = new RestAPIDirect(acc);
		api.request.connect((req) => start_update(req));
	}
	
	/* refresh timeline */
	public override void refresh(bool with_favorites = false) {
		if(lst.size == 0)
			set_empty();
		else
			update_content(template.generate_direct(lst, last_focused));
	}
	
	/* get new direct messages and update the list */
	public override ArrayList<Status>? update() {
		ArrayList<RestAPI.Status> result = null;
		string since_id = "";
		bool first_time = true;
		
		if(lst.size > 0) {
			since_id = lst.get(0).id;
			first_time = false;
		}
		
		try {
			result = api.get_timeline(_items_count, null, since_id);
		} catch(RestError e) {
			updating_error(e.message);
			return result;
		} catch(ParseError e) {
			updating_error(e.message);
			return result;
		}
		
		if(result.size > 0) { //if we get some statuses
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
	
	/* get older direct messages */
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
		} catch(ParseError e) {
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
	
	/* delete direct message with some id */
	protected override void destroy_status(string id) {
		try {
			api.destroy_status(id);
		} catch(RestError e) {
			updating_error(e.message);
			return;
		} catch(ParseError e) {
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
		
		refresh();
		
		deleted(_("Your direct message has been deleted successfully")); //signal
	}
}
