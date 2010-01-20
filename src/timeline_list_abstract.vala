using WebKit;
using RestAPI;
using Gee;
using Gtk;

public abstract class TimelineListAbstract : HBox {
	
	protected VBox vbox;
	protected WebView view;
	protected ScrolledWindow scroll;
	
	protected Template template;
	protected RestAPIAbstract api;
	protected ArrayList<RestAPI.Status> lst;
	
	private double current_scroll_pos;
	
	/* statuses in list */
	protected int _items_count;
	public int items_count {
		get { return _items_count; }
		set { _items_count = value; }
	}
	
	public Icon icon;
	public RadioAction act;
	
	//protected bool focused;
	protected int last_focused = 0; //time of the last readed status
	
	public signal void start_update();
	public signal void finish_update();
	public signal void updating_error(string msg);
	
	public TimelineListAbstract(AuthData auth_data, TimelineType timeline_type,
		IRestUrls urls, Template _template, int __items_count, Icon _icon,
		string fname, string icon_name, string icon_desc, bool _active = false) {
		
		view = new WebView();
		view.navigation_policy_decision_requested.connect(link_clicking);
		
		//return scroll position to the current
		view.load_finished.connect((f) => {
			((VScrollbar)scroll.get_vscrollbar()).set_value(current_scroll_pos);
		});
		
		scroll = new ScrolledWindow(null, null);
		scroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		scroll.add(view);
		
		vbox = new VBox(false, 0);
		vbox.pack_end(scroll, true, true, 0);
		
		this.pack_start(vbox, true, true, 0);
		
		api = new RestAPITimeline(urls, auth_data, timeline_type);
		template = _template;
		lst = new ArrayList<RestAPI.Status>();
		_items_count = __items_count;
		
		//create new action
		icon = _icon;
		act = new RadioAction(fname, icon_name, icon_desc, null, 0);
		act.set_gicon(icon);
		act.set_active(_active);
		act.changed.connect((current) => {
			if(act == current)
				show_smart();
			else
				hide_smart();
		});
	}
	
	public void set_auth(AuthData auth_data) {
		api.set_auth(auth_data);
	}
	
	public virtual void show_smart() {
		show();
		last_focused = (int)lst.get(0).created_at.mktime();
	}
	
	public virtual void hide_smart() {
		hide();
	}
	
	protected void update_content() {
		current_scroll_pos = ((VScrollbar)scroll.get_vscrollbar()).get_value();
		
		view.load_string(template.generate_timeline(lst, last_focused),
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
