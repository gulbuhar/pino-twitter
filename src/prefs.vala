/* prefs.vala
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

using GLib;
using Xml;

public class Prefs : Object {
	
	private string prefFilePath;
	
	private int _updateInterval = 5; //minutes
	public int updateInterval {
		get{ return _updateInterval; }
		set{ _updateInterval = value; }
	}
	
	private int _numberStatuses = 20;
	public int numberStatuses {
		get{ return _numberStatuses; }
		set{ _numberStatuses = value; }
	}
	
	private string _urlShorten = "goo.gl";
	public string urlShorten {
		get{ return _urlShorten; }
		set{ _urlShorten = value; }
	}
	
	private bool _showTimelineNotify = true;
	public bool showTimelineNotify {
		get{ return _showTimelineNotify; }
		set{ _showTimelineNotify = value; }
	}
	
	private bool _showMentionsNotify = true;
	public bool showMentionsNotify {
		get{ return _showMentionsNotify; }
		set{ _showMentionsNotify = value; }
	}
	
	private bool _showDirectNotify = true;
	public bool showDirectNotify {
		get{ return _showDirectNotify; }
		set{ _showDirectNotify = value; }
	}
	/*
	private bool _showFullNotify = true;
	public bool showFullNotify {
		get{ return _showFullNotify; }
		set{ _showFullNotify = value; }
	}
	*/
	private string _retweetStyle = "UNI";
	public ReTweet.Style retweetStyle {
		get{
			switch(_retweetStyle) {
				case "CLASSIC":
					return ReTweet.Style.CLASSIC;
				
				case "UNI":
					return ReTweet.Style.UNI;
				
				case "VIA":
					return ReTweet.Style.VIA;
				
				default:
					return ReTweet.Style.UNI;
			}
		}
		set{
			switch(value) {
				case ReTweet.Style.CLASSIC:
					_retweetStyle = "CLASSIC";
					break;
				
				case ReTweet.Style.UNI:
					_retweetStyle = "UNI";
					break;
				
				case ReTweet.Style.VIA:
					_retweetStyle = "VIA";
					break;
				
				default:
					_retweetStyle = "UNI";
					break;
			}
		}
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
	
	public signal void opacityTweetsChanged();
	private string _opacityTweets = "0.4";
	public string opacityTweets {
		get{ return _opacityTweets; }
		set{
			if(_opacityTweets != value) {
				_opacityTweets = value;
				opacityTweetsChanged();
			}
		}
	}
	
	public signal void rtlChanged();
	private bool _rtlSupport = false;
	public bool rtlSupport {
		get{ return _rtlSupport; }
		set{
			if(_rtlSupport != value) {
				_rtlSupport = value;
				rtlChanged();
			}
		}
	}
	
	public signal void fullNamesChanged();
	private bool _fullNames = false;
	public bool fullNames {
		get{ return _fullNames; }
		set{
			if(_fullNames != value) {
				_fullNames = value;
				fullNamesChanged();
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
	
	private bool _startMin = false;
	public bool startMin {
		get{ return _startMin; }
		set{ _startMin = value; }
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
				
				case "numberStatuses":
					_numberStatuses = iter->get_content().to_int();
					break;
				
				case "urlShorten":
					_urlShorten = iter->get_content();
					break;
				
				case "showTimelineNotify":
					_showTimelineNotify = iter->get_content().to_bool();
					break;
				
				case "showMentionsNotify":
					_showMentionsNotify = iter->get_content().to_bool();
					break;
				
				case "showDirectNotify":
					_showDirectNotify = iter->get_content().to_bool();
					break;
				/*
				case "showFullNotify":
					_showFullNotify = iter->get_content().to_bool();
					break;
				*/
				case "retweetStyle":
					_retweetStyle = iter->get_content();
					break;
				
				case "roundedAvatars":
					_roundedAvatars = iter->get_content().to_bool();
					break;
				
				case "opacityTweets":
					_opacityTweets = iter->get_content();
					break;
				
				case "rtlSupport":
					_rtlSupport = iter->get_content().to_bool();
					break;
				
				case "fullNames":
					_fullNames = iter->get_content().to_bool();
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
				
				case "startMin":
					_startMin = iter->get_content().to_bool();
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
        root->new_text_child(ns, "numberStatuses", _numberStatuses.to_string());
        root->add_content("\n");
        root->new_text_child(ns, "urlShorten", _urlShorten);
        root->add_content("\n");
        root->new_text_child(ns, "showTimelineNotify", _showTimelineNotify.to_string());
        root->add_content("\n");
        root->new_text_child(ns, "showMentionsNotify", _showMentionsNotify.to_string());
        root->add_content("\n");
        root->new_text_child(ns, "showDirectNotify", _showDirectNotify.to_string());
        root->add_content("\n");
        /*root->new_text_child(ns, "showFullNotify", _showFullNotify.to_string());
        root->add_content("\n");*/
        root->new_text_child(ns, "retweetStyle", _retweetStyle);
        root->add_content("\n");
        root->new_text_child(ns, "roundedAvatars", _roundedAvatars.to_string());
        root->add_content("\n");
        root->new_text_child(ns, "opacityTweets", _opacityTweets);
        root->add_content("\n");
        root->new_text_child(ns, "rtlSupport", _rtlSupport.to_string());
        root->add_content("\n");
        root->new_text_child(ns, "fullNames", _fullNames.to_string());
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
        root->new_text_child(ns, "startMin", _startMin.to_string());
        root->add_content("\n");
		
		//write this document to the pref file
		var stream = FileStream.open(prefFilePath, "w");
		//how does this work...
		Xml.Doc.dump(stream, xmldoc);
		
		return WriteStatus.OK;
	}
}
