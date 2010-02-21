/* main.vala
 *
 * Copyright (C) 2009-2010  troorl
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

using Unique;

public class Main {
	
  	public static int main (string[] args) {
		Unique.App app;
		Gtk.init(ref args);
		
		app = new Unique.App("org.pino.unique", null);
		
		if(app.is_running) { //not starting if already running
			Unique.Command command;
			Unique.Response response;
			Unique.MessageData message;
			message = new MessageData ();
			command = (Unique.Command) Unique.Command.ACTIVATE;
			response = app.send_message (command, message);
		
			if(response == Unique.Response.OK)
				return 0;
			else
				return 1;
		}
		
		Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALE_DIR);
    	Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
    	
		MainWindow window = new MainWindow();
		app.watch_window(window);
		
		Gtk.main();
		return 0;
  	}
}
