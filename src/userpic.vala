/* user_info_list.vala
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

public class Userpic : Image {
	
	private weak Thread thread_1;
	private string url;
	private Cache cache;
	
	public Userpic(Cache _cache) {
		cache = _cache;
		
		set_default();
	}
	
	public void set_default() {
		set_from_file(Config.USERPIC_PATH);
	}
	
	public void set_pic(string _url) {
		if (!Thread.supported()) {
			error("Cannot run without threads.");
			return;
		}
		
		url = _url;
		
		try {
			thread_1 = Thread.create(get_userpic, false);
		} catch(ThreadError e) {
			warning("Error: %s", e.message);
			return;
		}
	}
	
	private void *get_userpic() {
		string path = cache.get_or_download(url, Cache.Method.SYNC, true);
		
		set_from_file(path);
		
		return null;
	}
}
