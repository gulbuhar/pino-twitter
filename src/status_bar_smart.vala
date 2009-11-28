using Gtk;

public class StatusbarSmart : Statusbar {
	
	private Image statusImg;
	private Label statusLabel;
	
	public enum Status {
		UPDATED,
		UPDATING,
		SEND_STATUS,
		ERROR_401,
		ERROR_TIMEOUT,
		ERROR_UNKNOWN
	}
	
	public StatusbarSmart() {
		statusImg = new Image();
		this.pack_start(statusImg, false, false, 0);
		statusLabel = new Label("");
		this.pack_start(statusLabel, false, false, 0);
	}
	
	public void set_status(Status status) {
		switch(status) {
			case Status.UPDATED:
				statusImg.set_from_stock("gtk-apply", Gtk.IconSize.MENU);
				statusLabel.set_text("updated ");
				break;
			case Status.UPDATING:
				statusImg.set_from_stock("gtk-refresh", Gtk.IconSize.MENU);
				statusLabel.set_text("updating... ");
				break;
			case Status.SEND_STATUS:
				statusImg.set_from_stock("gtk-edit", Gtk.IconSize.MENU);
				statusLabel.set_text("sending status... ");
				break;
			case Status.ERROR_401:
				statusImg.set_from_stock("gtk-stop", Gtk.IconSize.MENU);
				statusLabel.set_text("wrong login or password ");
				break;
			case Status.ERROR_TIMEOUT:
				statusImg.set_from_stock("gtk-stop", Gtk.IconSize.MENU);
				statusLabel.set_text("problems with connection ");
				break;
			case Status.ERROR_UNKNOWN:
				statusImg.set_from_stock("gtk-stop", Gtk.IconSize.MENU);
				statusLabel.set_text("some strange error ");
				break;
		}
	}
}