using Gtk;

public class ReTweet : VBox {
	
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
				user_label.set_text("New status:");
			}
		}
	}
	
	private string _reply_id;
	public string reply_id {
		public get { return _reply_id; }
		public set { _reply_id = value; }
	}
	
	public void set_screen_name(string user_name) {
		user_label.set_text("Reply to <b>%s</b>:".printf(user_name));
		user_label.set_use_markup(true);
	}
	
	private Label label;
	public Label user_label;
	
	public string text {
		public owned get
		{ return entry.get_buffer().text; }
		set
		{ entry.get_buffer().set_text(value, (int)value.size()); }
	}
	
	public signal void enter_pressed();
	
	public ReTweet() {
		set_homogeneous(false);
		set_spacing(2);
		
		var l_box = new HBox(false, 2);
		user_label = new Label("New status:");
		l_box.pack_start(user_label, false, false, 2);
		
		entry = new TextView();
		entry.set_wrap_mode(Gtk.WrapMode.WORD);
		entry.key_press_event.connect(hide_or_send);
		entry.get_buffer().changed.connect(change);
		
		label = new Label("<b>140</b>");
		label.set_use_markup(true);
		
		var hbox = new HBox(false, 2);
		hbox.pack_start(entry, true, true, 0);
		hbox.pack_start(label, false, false, 10);
		
		pack_start(l_box, false, false, 2);
		pack_start(hbox, true, true, 2);
	}
	
	public void clear() {
		text = "";
	}
	
	public void insert(string str) {
		entry.get_buffer().insert_at_cursor(str, (int)str.length);
	}
	
	private bool hide_or_send(Gdk.EventKey event) {
		if(event.hardware_keycode == 36) { //return key
			enter_pressed();
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
		warning("text length: %d, substring length: %d", (int)text.len(), (int)text.substring(0, 140).len());
		
		if(length > 140) {
			string t = text.substring(0, 140);
			//warning(t);
			text = t;
		}
		
		label.set_text("<b>%s</b>".printf((140 - text.len()).to_string()));
		label.set_use_markup(true);
	}
}