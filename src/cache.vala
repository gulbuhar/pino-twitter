/* cache.vala
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

using Gee;

public class Cache : Object {
	
	public enum Method {SYNC, ASYNC}
	
	public signal void pic_downloaded(string url, string path);
	
	string cache_path;
	
	private HashMap<string, string> map;
	
	public Cache() {
		map = new HashMap<string, string>();
		check_cache_dir();
	}
	
	public string get_or_download(string url, Method method, bool need_emit) {
		//first look in hash
		var quick_response = map.get(url);
		if(quick_response != null)
			return quick_response;
		
		//get a file name
		string save_name = url.split("/")[4];
		
		//then look on disk
		string file_path = cache_path + "/" + save_name;
		var file =  File.new_for_path(file_path);
		if(file.query_exists(null)) {
			map.set(url, file_path);
			return file_path;
		}
		
		//and then try to download
		if(method == Method.ASYNC) {
			download_async.begin(url, save_name, need_emit);
			return url;
		}
		
		download(url, save_name);
		
		return file_path;
	}
	
	private void download(string url, string save_name) {
		var enc_name = Soup.form_encode("", save_name).split("=")[1];
		
		var pick = File.new_for_uri(url.replace(save_name, enc_name));
		var pick_file = File.new_for_path(cache_path + "/" + save_name);
		
		if(!pick_file.query_exists(null)) {
			pick.copy(pick_file, FileCopyFlags.NONE, null, null);
		}
	}
	
	private async void download_async(string url, string save_name, bool need_emit) {
		var enc_name = Soup.form_encode("", save_name).split("=")[1];
		
		var pick = File.new_for_uri(url.replace(save_name, enc_name));
		var pick_file = File.new_for_path(cache_path + "/" + save_name);
		
		if(!pick_file.query_exists(null)) {
			yield pick.copy_async(pick_file, FileCopyFlags.NONE, 1, null, null);
		}
		
		if(need_emit)
			pic_downloaded(url, cache_path + "/" + save_name);
	}
	
	private void check_cache_dir() {
		string conf_dir = Environment.get_home_dir() + "/.config/pino/";
		
		cache_path = conf_dir + "/cache";
		var cache_dir = File.new_for_path(cache_path);
		if(!cache_dir.query_exists(null))
			cache_dir.make_directory(null);
	}
	
	public void delete_cache() {
		var cache_dir = File.new_for_path(cache_path);
		var en = cache_dir.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME, 0, null);
		
		FileInfo file_info;
		while((file_info = en.next_file(null)) != null) {
			var d_file = File.new_for_path(cache_path + "/" + file_info.get_name ());
			d_file.delete(null);
		}
		
		//clear hash
		map.clear();
	}
}