/* main.vala
 *
 * Copyright (C) 2009  troorl
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 * 	troorl <troorl@gmail.com>
 */

using RestAPI;

public class Main {
	
  	public static int main (string[] args) {
		
		Gtk.init(ref args);
		
		Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALE_DIR);
    	Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
    	var urls = new TwitterUrls(); 
		var t = new RestAPITimeline(urls, TimelineType.HOME);
		try {
			t.get_timeline(2);
		} catch(RestError e) {
			warning(e.message);
		}
		//MainWindow window = new MainWindow();
		
		Gtk.main();
		return 0;
  	}
}
