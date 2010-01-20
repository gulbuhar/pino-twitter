using Gtk;

public class TrayIcon : StatusIcon {
	
	private Gdk.Pixbuf logo;
	private Gdk.Pixbuf logo_fresh;
	
	private Menu _popup;
	public Menu popup {
		get{ return popup; }
		set{ _popup = value; }
	}
	
	public TrayIcon(Gdk.Pixbuf _logo, Gdk.Pixbuf _logo_fresh) {
		base;
		
		logo = _logo;
		logo_fresh = _logo_fresh;
		set_from_pixbuf(logo);
		
		set_tooltip_text(_("%s - a twitter client").printf(Config.APPNAME));
		
		popup_menu.connect((button, activate_time) => {
			_popup.popup(null, null, null, button, activate_time);
		}); 
	}
	
	public void new_tweets(bool y) {
		if(y)
			set_from_pixbuf(logo_fresh);
		else
			set_from_pixbuf(logo);
	}
}
