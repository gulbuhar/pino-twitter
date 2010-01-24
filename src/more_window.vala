using Gtk;

public class MoreWindow : Window {
	
	ToolButton button;
	
	public signal void moar_event();
	
	public MoreWindow() {
		type = WindowType.POPUP;
		
		//set_position(WindowPosition.MOUSE);
		
		button = new ToolButton.from_stock(STOCK_GO_DOWN);
		button.set_tooltip_text(_("Get older entries"));
		button.set_size_request(40, 40);
		button.clicked.connect(() => moar_event());
		HBox hbox = new HBox(false, 0);
		hbox.pack_start(button, false, false, 0);
		add(hbox);
	}
	
	public void show_at(int x, int y) {
		move(x, y);
		show_all();
	}
	
	public void set_enabled(bool huh) {
		button.set_sensitive(huh);
	}
}
