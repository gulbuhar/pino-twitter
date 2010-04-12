/* dm_entry.vala
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
using RestAPI;

public class DmEntry : Entry {
	
	private RestAPIRe api;

	private bool _can_send = false;
	public bool can_send {
		get { return _can_send; }
	}
	
	public string warning_text {
		get { return _("You can't send direct message to this user. He (or she) must follow you too"); }
	}
	
	public DmEntry(RestAPIRe _api) {
		api = _api;
		
		set_icon_from_stock(EntryIconPosition.SECONDARY, "gtk-dialog-warning");
		set_icon_tooltip_text(EntryIconPosition.SECONDARY, _("Check"));
		icon_press.connect((pos, event) => {
			if(event.button.button == 1)
				check();
		});
		set_size_request(150, -1);
	}
	
	private void set_warning() {
		set_icon_from_stock(EntryIconPosition.SECONDARY, "gtk-dialog-warning");
		set_tooltip_text(warning_text);
		_can_send = false;
	}
	
	private void set_ok() {
		set_icon_from_stock(EntryIconPosition.SECONDARY, "gtk-apply");
		set_tooltip_text(_("You can send direct message to this user"));
		_can_send = true;
	}
	
	public void check() {
		/*if (!Thread.supported()) {
			error("Cannot run without threads.");
			return;
		}
		
		try {
			weak Thread thread_1 = Thread.create(get_friendship, false);
			thread_1.join();
		} catch(ThreadError e) {
			warning("Error: %s", e.message);
			return;
        }*/
        
        set_icon_from_stock(EntryIconPosition.SECONDARY, "gtk-refresh");
		set_tooltip_text(_("Checking..."));
		
		bool answer = false;
		
		try {
			answer = api.check_friendship(text);
		} catch(RestError e) {
			set_warning();
			return;
		} catch(ParseError e) {
			set_warning();
			return;
		}
		
		if(answer) {
			set_ok();
		} else {
			set_warning();
		}
	}
	
	/*
	private void* get_friendship() {
		set_icon_from_stock(EntryIconPosition.SECONDARY, "gtk-refresh");
		set_tooltip_text(_("Checking..."));
		
		bool answer = false;
		
		try {
			answer = api.check_friendship(text);
		} catch(RestError e) {
			set_warning();
			return null;
		}
		
		if(answer) {
			set_ok();
		} else {
			set_warning();
		}
		
		return null;
	}
	*/
}
