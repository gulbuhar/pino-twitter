using GLib;
using Xml;

public class Prefs : Object {
	
	private string prefFilePath;
	
	private int _updateInterval = 5; //minutes
	public int updateInterval {
		get{ return _updateInterval; }
		set{ _updateInterval = value; }
	}
	
	private bool _showNotifications = true;
	public bool showNotifications {
		get{ return _showNotifications; }
		set{ _showNotifications = value; }
	}
	
	public signal void roundedAvatarsChanged();
	private bool _roundedAvatars = true;
	public bool roundedAvatars {
		get{ return _roundedAvatars; }
		set{
			if(_roundedAvatars != value) {
				_roundedAvatars = value;
				roundedAvatarsChanged();
			}
		}
	}
	
	private string _login = "";
	public string login {
		get{ return _login; }
		set{ _login = value; }
	}
	
	private string _password = "";
	public string password {
		get{ return _password; }
		set {
			is_new = true;
			_password = value;
		}
	}
	
	private bool _rememberPass = true;
	public bool rememberPass {
		get{ return _rememberPass; }
		set{ _rememberPass = value; }
	}
	
	private int _width = 250;
	public int width {
		get{ return _width; }
		set{ _width = value; }
	}
	
	private int _height = 500;
	public int height {
		get{ return _height; }
		set{ _height = value; }
	}
	
	private int _left = -1;
	public int left {
		get{ return _left; }
		set{ _left = value; }
	}
	
	private int _top = -1;
	public int top {
		get{ return _top; }
		set{ _top = value; }
	}
	
	private bool _menuShow = true;
	public bool menuShow {
		get{ return _menuShow; }
		set{ _menuShow = value; }
	}
	
	private bool _toolbarShow = true;
	public bool toolbarShow {
		get{ return _toolbarShow; }
		set{ _toolbarShow = value; }
	}
	
	public enum LoadStatus { OK, EMPTY, ERROR }
	public enum WriteStatus { OK, ERROR }
	
	public bool is_new = false;
	
	public Prefs() {
		var load_status = load();
		
		if(load_status == LoadStatus.EMPTY) {
			write();
		}
	}
	
	public LoadStatus load() {
		string conf_dir = Environment.get_home_dir() + "/.config/";
		
		var dir = File.new_for_path(conf_dir);
		if(!dir.query_exists(null))
			dir.make_directory(null);
		
		string pino_dir = conf_dir + "/pino";
		
		dir = File.new_for_path(pino_dir);
		if(!dir.query_exists(null))
			dir.make_directory(null);
		
		dir = null;
		
		//checking for settings file and creating if necessary
		prefFilePath = pino_dir + "/settings.xml";
		var pref_file = File.new_for_path(prefFilePath);
		
		if(!pref_file.query_exists(null)) {
			//var pref_stream = pref_file.create(FileCreateFlags.NONE, null);
			is_new = true;
			return LoadStatus.EMPTY;
		}
		
		//reading content
		string content;
		{
			var stream = new DataInputStream(pref_file.read(null));
			content = stream.read_until("", null, null);
		}
		
		return parse(content);
	}
	
	private LoadStatus parse(string content) {
		//parsing config
		Xml.Doc* xmlDoc = Parser.parse_memory(content, (int)content.length);
		Xml.Node* rootNode = xmlDoc->get_root_element();
		
		for(Xml.Node* iter = rootNode->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE)
				continue;
			
			switch(iter->name) {
				case "updateInterval":
					_updateInterval = iter->get_content().to_int();
					break;
				
				case "showNotifications":
					_showNotifications = iter->get_content().to_bool();
					break;
				
				case "roundedAvatars":
					_roundedAvatars = iter->get_content().to_bool();
					break;
				
				case "login":
					_login = iter->get_content();
					break;
				
				case "password":
					_password = iter->get_content();
					/*if(_password == "")
						is_new = true;*/
					break;
				
				case "rememberPass":
					_rememberPass = iter->get_content().to_bool();
					break;
				
				case "width":
					_width = iter->get_content().to_int();
					break;
				
				case "height":
					_height = iter->get_content().to_int();
					break;
				
				case "left":
					_left = iter->get_content().to_int();
					break;
				
				case "top":
					_top = iter->get_content().to_int();
					break;
				
				case "menuShow":
					_menuShow = iter->get_content().to_bool();
					break;
				
				case "toolbarShow":
					_toolbarShow = iter->get_content().to_bool();
					break;
			}
		}
		
		return LoadStatus.OK;
	}
	
	public WriteStatus write() {
		//creating xml document
		Xml.Doc* xmldoc = new Xml.Doc("1.0");
		Xml.Ns* ns = Xml.Ns.create(null, null, null);
		ns->type = Xml.ElementType.ELEMENT_NODE;
		Xml.Node* root = new Xml.Node(ns, "settings");
		xmldoc->set_root_element(root);
        
        //creating properties
        root->add_content("\n");
        root->new_text_child(ns, "updateInterval", _updateInterval.to_string());
        root->add_content("\n");
        root->new_text_child(ns, "showNotifications", _showNotifications.to_string());
        root->add_content("\n");
        root->new_text_child(ns, "roundedAvatars", _roundedAvatars.to_string());
        root->add_content("\n");
        root->new_text_child(ns, "login", _login);
        root->add_content("\n");
        if(rememberPass)
        	root->new_text_child(ns, "password", _password);
        else
        	root->new_text_child(ns, "password", "");
        root->add_content("\n");
        root->new_text_child(ns, "rememberPass", _rememberPass.to_string());
        root->add_content("\n");
        root->new_text_child(ns, "width", _width.to_string());
        root->add_content("\n");
        root->new_text_child(ns, "height", _height.to_string());
        root->add_content("\n");
        root->new_text_child(ns, "left", _left.to_string());
        root->add_content("\n");
        root->new_text_child(ns, "top", _top.to_string());
        root->add_content("\n");
        root->new_text_child(ns, "menuShow", _menuShow.to_string());
        root->add_content("\n");
        root->new_text_child(ns, "toolbarShow", _toolbarShow.to_string());
        root->add_content("\n");
		
		//write this document to the pref file
		var stream = FileStream.open(prefFilePath, "w");
		//how does this work...
		Xml.Doc.dump(stream, xmldoc);
		
		return WriteStatus.OK;
	}
}