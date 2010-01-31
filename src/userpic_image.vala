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
