/* timeline_list_abstract.vala
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

using WebKit;
using Auth;
using RestAPI;
using Gee;
using Gtk;

public abstract class TimelineListAbstract : HBox {
	
	protected VBox vbox;
	protected WebView view;
	protected ScrolledWindow scroll;
	
	protected MoreWindow more;
	
	protected Template template;
	protected RestAPIAbstract api;
	protected ArrayList<RestAPI.Status> lst;
	
	protected double current_scroll_pos;
	
	/* statuses in list */
	protected int _items_count;
	public int items_count {
		get { return _items_count; }
		set { _items_count = value; }
	}
	
	public Icon icon;
	public RadioAction act;
	
	private Menu _popup;
	public Menu popup {
		set { _popup = value; }
	}
	
	//protected bool focused;
	protected int last_focused = 0; //time of the last readed status
	
	protected Window parent;
	
	protected Accounts accounts;
	
	public signal void start_update(string req);
	public signal void finish_update();
	public signal void updating_error(string msg);
	
	public signal void nickto(string screen_name);
	public signal void replyto(Status status);
	public signal void retweet(Status status);
	public signal void directreply(string screen_name);
	
	//focus of the main window
	public virtual bool parent_focus {
		get { return false; }
		set {
			if(!value)
				more.hide();
		}
	}
	
	public TimelineListAbstract(Window _parent, Accounts _accounts, TimelineType timeline_type,
		Template _template, int __items_count, Icon _icon,
		string fname, string icon_name, string icon_desc, bool _active = false) {
		
		accounts = _accounts;
		
		view = new WebView();
		view.navigation_policy_decision_requested.connect(link_clicking);
		
		//return scroll position to the current
		view.load_finished.connect((f) => {
			((VScrollbar)scroll.get_vscrollbar()).set_value(current_scroll_pos);
		});
		
		more = new MoreWindow();
		more.moar_event.connect(get_older);
		
		scroll = new ScrolledWindow(null, null);
		scroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		scroll.add(view);
		
		vbox = new VBox(false, 0);
		vbox.pack_end(scroll, true, true, 0);
		
		var event_view = new EventBox();
		event_view.add(vbox);
		event_view.set_events(Gdk.EventMask.BUTTON_MOTION_MASK);
		event_view.motion_notify_event.connect((event) => {
			int height = allocation.height;
			if(height - event.y > 20 && height - event.y < 60 && event.x > 20 && event.x < 60) {
				int ax = (int)(event.x_root - event.x + 20);
				int ay = (int)(event.y_root + height - event.y - 60);
				more.show_at(ax, ay);
				//warning("motion: %fx%f", ax, ay);
				//warning("root: %fx%f", event.x_root, event.y_root);
			} else {
				if(more.visible)
					more.hide();
			}
			return true;
		});
		
		this.pack_start(event_view, true, true, 0);
		//this.pack_start(fixed, true, true, 0);
		
		var acc = accounts.get_current_account();
		api = new RestAPITimeline(acc, timeline_type);
		api.request.connect((req) => start_update(req));
		template = _template;
		template.emit_for_refresh.connect(() => refresh());
		lst = new ArrayList<RestAPI.Status>();
		_items_count = __items_count;
		parent = _parent;
		parent.focus_in_event.connect((w, e) => {
			parent_focus = true;
			return true;
		});
		parent.focus_out_event.connect((w, e) => {
			parent_focus = false;
			return true;
		});
		
		//create new action
		icon = _icon;
		act = new RadioAction(fname, icon_name, icon_desc, null, 0);
		act.set_gicon(icon);
		act.set_active(_active);
		act.changed.connect((current) => {
			if(act == current)
				show_smart();
			else
				hide_smart();
		});
		
		//popup menu actions
		view.button_press_event.connect(show_popup_menu);
		
		if(accounts.accounts.size > 0)
			start_screen();
		else
			set_empty();
	}
	
	public void set_empty() {
		lst.clear();
		last_focused = 0;
		update_content(template.generate_message(_("Empty")));
	}
	
	public virtual ArrayList<Status>? update() {
		return null;
	}
	
	public void update_auth() {
		var acc = accounts.get_current_account();
		api.set_auth(acc);
		
		lst.clear();
		last_focused = 0;
		
		if(acc == null)
			set_empty();
		else {
			start_screen();
			update();
		}
	}
	
	public virtual void show_smart() {
		show();
		last_focused = (int)lst.get(0).created_at.mktime();
	}
	
	public virtual void hide_smart() {
		hide();
	}
	
	protected void start_screen() {
		update_content(template.generate_message(_("Connecting...")));
	}
	
	protected virtual void update_content(string content) {
		current_scroll_pos = ((VScrollbar)scroll.get_vscrollbar()).get_value();
		
		view.load_string(content, "text/html", "utf8", "file:///");
	}
	
	protected virtual void destroy_status(string id) {}
	
	protected abstract void get_older();
	
	public abstract void refresh();
	
	/* removing extra statuses or messages */
	protected void delete_extra() {
		while(lst.size > _items_count)
			lst.remove_at(lst.size - 1);
	}
	
	private bool link_clicking(WebFrame p0, NetworkRequest request,
		WebNavigationAction action, WebPolicyDecision decision) {
		if(request.uri == "")
			return false;
		
		var p = request.uri.split("://");
		var prot = p[0];
		var params = p[1];
		
		if(prot == "http" || prot == "https" || prot == "ftp") {
			GLib.Pid pid;
			GLib.Process.spawn_async(".", {"/usr/bin/xdg-open", request.uri}, null,
				GLib.SpawnFlags.STDOUT_TO_DEV_NULL, null, out pid);
			return true;
		}
		
		switch(prot) {
			case "nickto":
				nickto(params);
				return true;
			
			case "directreply":
				string screen_name = params;
				directreply(screen_name);
				return true;
			
			case "replyto":
				string status_id = params;
				replyto(find_status(status_id));
				return true;
			
			case "retweet":
				string status_id = params;
				retweet(find_status(status_id));
				return true;
			
			case "delete":
				var message_dialog = new MessageDialog(parent,
					Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
					Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO,
					(_("Sure you want to delete this status?")));
				
				var response = message_dialog.run();
				if(response == ResponseType.YES) {
					message_dialog.destroy();
					var status_id = params;
					warning(status_id);
					destroy_status(status_id);
				}
				message_dialog.destroy();
				
				return true;
			
			case "file":
				return false;
			
			default:
				return true;
		}
	}
	
	/* get status by id */
	private Status find_status(string id) {
		Status st = null;
		foreach(Status _status in lst) {
			if(_status.id == id) {
				st = _status;
				break;
			}
		}
		return st;
	}
	
	/* show popup menu */
	private bool show_popup_menu(Gdk.EventButton event) {
		if((event.type == Gdk.EventType.BUTTON_PRESS) && (event.button == 3)) {
			if(_popup != null)
				_popup.popup(null, null, null, event.button, event.time);
			
			return true;
		}
		
		return false;
	}
}
