/* list_abstract.vala
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
const string a = """
public abstract class ListAbstract : WebView {
	
	protected Template template;
	protected RestAPIAbstract api;
	protected ArrayList<RestAPI.Status> lst;
	
	/* statuses in list */
	protected int _items_count;
	public int items_count {
		get { return _items_count; }
		set { _items_count = value; }
	}
	
	protected bool focused;
	protected int last_focused = 0; //time of the last readed status
	
	public signal void start_update();
	public signal void finish_update();
	public signal void updating_error(string msg);
	
	public ListAbstract(Accounts _accounts, TimelineType timeline_type,
		Template _template, int __items_count) {
		
		var acc = _accounts.get_current_account();
		AuthData auth_data = {acc.login, acc.password, acc.service};
		api = new RestAPITimeline(auth_data, timeline_type);
		template = _template;
		lst = new ArrayList<RestAPI.Status>();
		_items_count = __items_count;
		
		navigation_policy_decision_requested.connect(link_clicking);
	}
	
	public void set_auth(AuthData auth_data) {
		api.set_auth(auth_data);
	}
	
	public void show_smart() {
		show();
		set_focus(true);
	}
	
	public void hide_smart() {
		hide();
		set_focus(false);
	}
	
	protected void set_focus(bool focus) {
		focused = focus;
		
		if(focused) {
			last_focused = (int)lst.get(0).created_at.mktime();
		}
	}
	
	protected void update_content() {
		load_string(template.generate_timeline(lst, last_focused),
			"text/html", "utf8", "file:///");
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
				/*
				reTweet.show();
				reTweet.insert("@" + params);
				this.set_focus(reTweet.text_entry);
				*/
				return true;
			
			case "directreply":
				/*
				var screen_name = params;
				reTweet.is_direct = true;
				reTweet.set_screen_name(screen_name.split("==")[1]);
				reTweet.reply_id = screen_name.split("==")[0];
				reTweet.show();
				reTweet.insert("@%s ".printf(screen_name.split("==")[1]));
				this.set_focus(reTweet.text_entry);
				*/
				return true;
			
			case "retweet":
				/*
				var status_id = params;
				var tweet = twee.get_status(status_id);
				
				
					reTweet.clear();
					reTweet.show();
					reTweet.set_retweet(tweet, prefs.retweetStyle);
					this.set_focus(reTweet.text_entry);
				
				*/
				return true;
			
			case "delete":
				/*
				var message_dialog = new MessageDialog(this,
					Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
					Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO,
					(_("Sure you want to delete this tweet?")));
				
				var response = message_dialog.run();
				if(response == ResponseType.YES) {
					message_dialog.destroy();
					var status_id = params;
					warning(status_id);
					var reply = twee.destroyStatus(status_id);
					status_actions(reply);
				}
				message_dialog.destroy();
				*/
				return true;
			
			case "file":
				return false;
			
			default:
				return true;
		}
	}
}
""";
