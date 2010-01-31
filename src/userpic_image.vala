/* userpic_image.vala
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
using Soup;
using Xml;
using RestAPI;

public class UserpicImage : Image {
	
	private Cache cache;
	
	weak Thread thread_1;
	RestAPIRe api;
	
	public UserpicImage(Cache _cache, RestAPIRe _api) {
		base;
		cache = _cache;
		api = _api;
	}
	
	public void update() {
		if (!Thread.supported()) {
			error("Cannot run without threads.");
			return;
		}
		
		try {
			thread_1 = Thread.create(get_userpic, false);
		} catch(ThreadError e) {
			warning("Error: %s", e.message);
			return;
        }
	}
	
	private void *get_userpic() {
		string url = api.get_userpic_url();
		string path = cache.get_or_download(url, Cache.Method.SYNC, true);
		
		set_from_file(path);
		
		return null;
	}
}
