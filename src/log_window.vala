/* log_window.vala
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
