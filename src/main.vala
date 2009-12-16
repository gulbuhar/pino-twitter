public class Main {
	
  	public static int main (string[] args) {
		
		Gtk.init(ref args);
		
		Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALE_DIR);
    	Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
		
		MainWindow window = new MainWindow();
		
		Gtk.main();
		return 0;
  	}
}
