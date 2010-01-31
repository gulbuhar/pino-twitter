using WebKit;
using RestAPI;
using Gee;

public abstract class ListAbstract : WebView {
	
	protected Template template;
	protected RestAPIAbstract api;
	protected ArrayList<RestAPI.Status> lst;
	
	/* statuses in list */
	protected int _items_count;
	public int items_count {
		get { return _items_count; }
		set { _items_count = value; }
	}
	
	protected bool focused;
	protected int last_focused = 0; //time of the last readed status
	
	public signal void start_update();
	public signal void finish_update();
	public signal void updating_error(string msg);
	
	public ListAbstract(AuthData auth_data, TimelineType timeline_type,
		IRestUrls urls, Template _template, int __items_count) {
		
		api = new RestAPITimeline(urls, auth_data, timeline_type);
		template = _template;
		lst = new ArrayList<RestAPI.Status>();
		_items_count = __items_count;
		
		navigation_policy_decision_requested.connect(link_clicking);
	}
	
	public void set_auth(AuthData auth_data) {
		api.set_auth(auth_data);
	}
	
	public void show_smart() {
		show();
		set_focus(true);
	}
	
	public void hide_smart() {
		hide();
		set_focus(false);
	}
	
	protected void set_focus(bool focus) {
		focused = focus;
		
		if(focused) {
			last_focused = (int)lst.get(0).created_at.mktime();
		}
	}
	
	protected void update_content() {
		load_string(template.generate_timeline(lst, last_focused),
			"text/html", "utf8", "file:///");
	}
	
	private bool link_clicking(WebFrame p0, NetworkRequest request,
		WebNavigationAction action, WebPolicyDecision decision) {
		if(request.uri == "")
			return false;
		
		var p = request.uri.split("://");
		var prot = p[0];
		var params = p[1];
		
		if(prot == "http" || prot == "https" || prot == "ftp") {
			GLib.Pid pid;
			GLib.Process.spawn_async(".", {"/usr/bin/xdg-open", request.uri}, null,
				GLib.SpawnFlags.STDOUT_TO_DEV_NULL, null, out pid);
			return true;
		}
		
		switch(prot) {
			case "nickto":
				/*
				reTweet.show();
				reTweet.insert("@" + params);
				this.set_focus(reTweet.text_entry);
				*/
				return true;
			
			case "directreply":
				/*
				var screen_name = params;
				reTweet.is_direct = true;
				reTweet.set_screen_name(screen_name.split("==")[1]);
				reTweet.reply_id = screen_name.split("==")[0];
				reTweet.show();
				reTweet.insert("@%s ".printf(screen_name.split("==")[1]));
				this.set_focus(reTweet.text_entry);
				*/
				return true;
			
			case "retweet":
				/*
				var status_id = params;
				var tweet = twee.get_status(status_id);
				
				
					reTweet.clear();
					reTweet.show();
					reTweet.set_retweet(tweet, prefs.retweetStyle);
					this.set_focus(reTweet.text_entry);
				
				*/
				return true;
			
			case "delete":
				/*
				var message_dialog = new MessageDialog(this,
					Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
					Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO,
					(_("Sure you want to delete this tweet?")));
				
				var response = message_dialog.run();
				if(response == ResponseType.YES) {
					message_dialog.destroy();
					var status_id = params;
					warning(status_id);
					var reply = twee.destroyStatus(status_id);
					status_actions(reply);
				}
				message_dialog.destroy();
				*/
				return true;
			
			case "file":
				return false;
			
			default:
				return true;
		}
	}
}