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
	
	private RestAPIRe api;
	private Image userpic;
	
	private TextView entry;
	public TextView text_entry {
		public get { return entry; }
	}
	
	private bool _is_direct = false;
	public bool is_direct {
		public get { return _is_direct; }
		public set {
			_is_direct = value;
			if(!value) {
				_reply_id = "";
				user_label.set_text(_("New status:"));
			}
		}
	}
	
	private string _reply_id;
	public string reply_id {
		public get { return _reply_id; }
		public set { _reply_id = value; }
	}
	
	public string text {
		public owned get
		{ return entry.get_buffer().text; }
		set
		{ entry.get_buffer().set_text(value, (int)value.size()); }
	}
	
	private Label label;
	public Label user_label;
	
	public signal void enter_pressed();
	public signal void empty_pressed();
	
	public ReTweet() {
		border_width = 0;
		
		set_homogeneous(false);
		set_spacing(2);
		
		var l_box = new HBox(false, 2);
		user_label = new Label(_("New status:"));
		
		label = new Label("<b>140</b>");
		label.set_use_markup(true);
		
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
		//hbox.pack_start(label, false, false, 2);
		
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
	
	public void clear() {
		text = "";
	}
	
	public void insert(string str) {
		entry.get_buffer().insert_at_cursor(str, (int)str.length);
	}
	
	public void set_retweet(Status tweet, ReTweet.Style style) {
		user_label.set_text(_("Retweet:"));
		
		switch(style) {
			case ReTweet.Style.UNI:
				text = "♺ @%s: %s".printf(tweet.user_screen_name, tweet.text);
				break;
			
			case ReTweet.Style.CLASSIC:
				text = "RT @%s: %s".printf(tweet.user_screen_name, tweet.text);
				break;
			
			case ReTweet.Style.VIA:
				var msg = tweet.text;
				var via = " via @%s".printf(tweet.user_screen_name);
				
				if(msg.length > (140 - via.length))
					msg = msg.substring(0, 140 - via.length);
				
				text = msg + via;
				break;
		}
		
	}
	
	private bool hide_or_send(Gdk.EventKey event) {
		if(event.hardware_keycode == 36) { //return key
			if(event.state == 1) { //shift + enter
				entry.get_buffer().insert_at_cursor("\n", (int)"\n".length);
				return true;
			}
			if(text.length > 0)
				enter_pressed();
			else
				empty_pressed();
			return true;
		}
		
		if(event.hardware_keycode == 9) { //esc key
			clear();
			is_direct = false;
			hide();
		}
		
		return false;
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
