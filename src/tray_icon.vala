using Gtk;

public class TrayIcon : StatusIcon {
	
	private Window parent;
	private Gdk.Pixbuf logo;
	private Gdk.Pixbuf logo_fresh;
	
	private Menu _popup;
	public Menu popup {
		get{ return popup; }
		set{ _popup = value; }
	}
	
	public TrayIcon(Window _parent, Gdk.Pixbuf _logo, Gdk.Pixbuf _logo_fresh) {
		base;
		
		parent = _parent;
		logo = _logo;
		logo_fresh = _logo_fresh;
		set_from_pixbuf(logo);
		
		set_tooltip_text(_("%s - a twitter client").printf(Config.APPNAME));
		
		popup_menu.connect((button, activate_time) => {
			_popup.popup(null, null, null, button, activate_time);
		});
		
		activate.connect(() => {
			if(parent.visible)
				parent.hide();
			else
				parent.show();
		});
	}
	
	public void new_tweets(bool y) {
		if(y)
			set_from_pixbuf(logo_fresh);
		else
			set_from_pixbuf(logo);
	}
}
