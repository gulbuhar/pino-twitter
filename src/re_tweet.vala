/* re_tweet.vala
 *
 * Copyright (C) 2009  troorl
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

public class ReTweet : VBox {
	
	public static enum Style { CLASSIC, UNI, VIA }
	
	private static enum State { NEW, REPLY, DIRECT_REPLY, RETWEET }
	
	private State state;
	
	private RestAPIRe api;
	private Image userpic;
	
	private TextView entry;
	public TextView text_entry {
		public get { return entry; }
	}
	
	public string text {
		public owned get
		{ return entry.get_buffer().text; }
		set
		{ entry.get_buffer().set_text(value, (int)value.size()); }
	}
	
	private Image status_icon;
	private Label label;
	public Label user_label;
	
	private Window parent;
	private Prefs prefs;
	
	private string reply_id = "";
	
	public signal void status_updated(Status status);
	
	public ReTweet(Window _parent, Prefs _prefs) {
		parent = _parent;
		prefs = _prefs;
		
		api = new RestAPIRe(new TwitterUrls(), {prefs.login, prefs.password});
		
		//gui setup
		border_width = 0;
		set_homogeneous(false);
		set_spacing(2);
		
		var l_box = new HBox(false, 2);
		status_icon = new Image();
		user_label = new Label(_("New status:"));
		
		label = new Label("<b>140</b>");
		label.set_use_markup(true);
		
		l_box.pack_start(status_icon, false, false, 2);
		l_box.pack_start(user_label, false, false, 2);
		l_box.pack_end(label, false, false, 2);
		
		entry = new TextView();
		entry.set_size_request(-1, 48);
		entry.cursor_visible = true;
		entry.set_wrap_mode(Gtk.WrapMode.WORD);
		entry.key_press_event.connect(hide_or_send);
		entry.get_buffer().changed.connect(change);
		
		var scroll = new ScrolledWindow(null, null);
        scroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        scroll.add(entry);
		
		userpic = new Image();
		userpic.set_size_request(48, 48);
		
		var hbox = new HBox(false, 1);
		hbox.pack_start(scroll, true, true, 0);
		hbox.pack_start(userpic, false, false, 0);
		
		var frame = new Frame(null);
		frame.set_size_request(-1, 48);
		frame.add(hbox);
		
		var sep = new HSeparator();
		
		pack_start(sep, false, false, 0);
		pack_start(l_box, false, false, 0);
		pack_start(frame, false, true, 0);
	}
	
	public void set_screen_name(string user_name) {
		user_label.set_text(_("Reply to <b>%s</b>:").printf(user_name));
		user_label.set_use_markup(true);
	}
	
	public void set_userpic(string path) {
		var buf = new Gdk.Pixbuf.from_file(path);
		
		if(buf.width > 48 || buf.height > 48)
			buf = buf.scale_simple(48, 48, Gdk.InterpType.BILINEAR);
		
		userpic.set_from_pixbuf(buf);
	}
	
	private void clear() {
		text = "";
	}
	
	public void insert(string str) {
		entry.get_buffer().insert_at_cursor(str, (int)str.length);
	}
	
	public void set_state_new() {
		state = State.NEW;
		
		clear();
		show();
		status_icon.set_from_stock(STOCK_EDIT, IconSize.SMALL_TOOLBAR);
		parent.set_focus(text_entry);
	}
	
	public void set_state_reply(Status status) {
		state = State.REPLY;
		reply_id = status.id;
		
		clear();
		show();
		
		status_icon.set_from_file(Config.REPLY_PATH);
		user_label.set_text(_("Reply to") + " <b>%s</b>:".printf(status.user_screen_name));
		user_label.set_use_markup(true);
		text = "@%s ".printf(status.user_screen_name);
		parent.set_focus(text_entry);
	}
	
	public void set_state_directreply(string screen_name) {
		state = State.DIRECT_REPLY;
		
		clear();
		show();
		
		status_icon.set_from_file(Config.DIRECT_REPLY_PATH);
		user_label.set_text(_("Direct message to") + " <b>%s</b>:".printf(screen_name));
		user_label.set_use_markup(true);
		parent.set_focus(text_entry);
	}
	
	public void set_state_retweet(Status status) {
		state = State.RETWEET;
		
		clear();
		show();
		
		status_icon.set_from_file(Config.RETWEET_PATH);
		user_label.set_text(_("Retweet:"));
		
		switch(prefs.retweetStyle) {
			case ReTweet.Style.UNI:
				text = "♺ @%s: %s".printf(status.user_screen_name, status.text);
				break;
			
			case ReTweet.Style.CLASSIC:
				text = "RT @%s: %s".printf(status.user_screen_name, status.text);
				break;
			
			case ReTweet.Style.VIA:
				var msg = status.text;
				var via = " via @%s".printf(status.user_screen_name);
				
				if(msg.length > (140 - via.length))
					msg = msg.substring(0, 140 - via.length);
				
				text = msg + via;
				break;
		}
		
		parent.set_focus(text_entry);
	}
	
	private bool hide_or_send(Gdk.EventKey event) {
		switch(event.hardware_keycode) {
			case 36: //return key
				if(event.state == 1) { //shift + enter
					entry.get_buffer().insert_at_cursor("\n", (int)"\n".length);
					return true;
				}
				if(text.length > 0) {
					enter_pressed();
				} else { // if nothing to send
					var message_dialog = new MessageDialog(parent,
					Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
					Gtk.MessageType.INFO, Gtk.ButtonsType.OK,
					(_("Type something first")));
					
					message_dialog.run();
					message_dialog.destroy();
				}
				return true;
		
		case 9: //esc key
			clear();
			hide();
			break;
		}
		
		return false;
	}
	
	private void enter_pressed() {
		switch(state) {
			case State.NEW:
				send_new();
				break;
			
			case State.REPLY:
				send_new(reply_id);
				break;
			
			case State.RETWEET:
				send_new();
				break;
		}
	}
	
	private void send_new(string reply_id = "") {
		set_sensitive(false);
		
		Status status = null;
		try {
			status = api.update_status(text, reply_id);
		} catch(RestError e) {
			set_sensitive(true);
			warning(e.message);
			return;
		}
		
		status_updated(status); //send_signal
		
		hide();
		set_sensitive(true);
	}
	
	private void change() {
		int length = (int)text.len();
		
		if(length > 140) {
			string t = text.substring(0, 140);
			//warning(t);
			text = t;
		}
		
		label.set_text("<b>%s</b>".printf((140 - text.len()).to_string()));
		label.set_use_markup(true);
	}
}
