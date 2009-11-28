public class Main {
	
  	public static int main (string[] args) {
		
		Gtk.init(ref args);
		MainWindow window = new MainWindow();
		
		Gtk.main();
		return 0;
  	}
}
