using Gtk;

public class HigTable : VBox {
	
	public HigTable(string title) {
		spacing = 0;
		homogeneous = false;
		
		var title_label = new Label("<b>%s</b>".printf(title));
		title_label.set_use_markup(true);
		
		var hbox = new HBox(false, 0);
		
		hbox.pack_start(title_label, false, false, 10);
		pack_start(hbox, false, false, 0);
	}
	
	public void add_widget(Widget w) {
		var hbox = new HBox(false, 0);
		hbox.pack_start(w, false, false, 20);
		pack_start(hbox, false, false, 2);
	}
	
	public void add_two_widgets(Widget w1, Widget w2) {
		var hbox = new HBox(false, 0);
		hbox.pack_start(w1, false, true, 20);
		hbox.pack_end(w2, false, true, 20);
		pack_start(hbox, false, false, 2);
	}
}