using Gtk;

public class StatusbarSmart : VBox {
	public enum Status {
		UPDATED,
		UPDATING,
		SEND_STATUS,
		ERROR_401,
		ERROR_TIMEOUT,
		ERROR_UNKNOWN
	}
	
	private HSeparator sep;
	private Image img;
	private Label label;
	
	public StatusbarSmart() {
		sep = new HSeparator();
		img = new Image();
		label = new Label("");
		
		var hbox = new HBox(false, 5);
		hbox.pack_start(img, false, false, 0);
		hbox.pack_start(label, false, false, 0);
		
		pack_start(sep, false, false, 0);
		pack_start(hbox, false, false, 0);
	}
	
	private void push(string icon, string text) {
		img.set_from_stock(icon, Gtk.IconSize.MENU);
		label.set_label(text);
	}
	
	public void set_status(Status status) {
		switch(status) {
			case Status.UPDATED:
				push("gtk-apply", _("updated "));
				break;
			
			case Status.UPDATING:
				push("gtk-refresh", _("updating... "));
				break;
			
			case Status.SEND_STATUS:
				push("gtk-edit", _("sending status... "));
				break;
			
			case Status.ERROR_401:
				push("gtk-stop", _("wrong login or password "));
				break;
			
			case Status.ERROR_TIMEOUT:
				push("gtk-stop", _("problems with connection "));
				break;
			
			case Status.ERROR_UNKNOWN:
				push("gtk-stop", _("some strange error "));
				break;
		}
	}
}