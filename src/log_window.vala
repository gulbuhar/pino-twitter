using Gtk;

public class LogWindow : Window {
	
	TextView text_log;
	
	public LogWindow(string log) {
		set_size_request(400, 400);
		
		text_log = new TextView();
		text_log.get_buffer().set_text(log, (int)log.size());
		var scroll = new ScrolledWindow(null, null);
		scroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        scroll.add(text_log);
        
        var vbox = new VBox(false, 0);
        vbox.pack_start(scroll, true, true, 0);
        
		var hbox = new HBox(false, 0);
		hbox.pack_start(vbox, true, true, 0);
		
		add(hbox);
	}
}
