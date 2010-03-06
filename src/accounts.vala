/* accounts.vala
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

using Xml;
using Gee;

namespace Auth {

public class Account : Object {
	
	private string _login;
	public string login {
		get { return _login; }
		set { _login = value; }
	}
	
	private string _password;
	public string password {
		get { return _password; }
		set { _password = value; }
	}
	
	private string _service;
	public string service {
		get { return _service; }
		set { _service = value; }
	}
	
	private string _proxy = "";
	public string proxy {
		get { return _proxy; }
		set { _proxy = value; }
	}
	
	private bool _active;
	public bool active {
		get { return _active; }
		set { _active = value; }
	}
	
	public Account.with_data(string __login, string __password, string __service,
		bool __active) {
		_login = __login;
		_password = __password;
		_service = __service;
		_active = __active;
	}
}

public class Accounts : Object {
	
	private ArrayList<Account?> acc_lst;
	public ArrayList<Account?> accounts {
		get { return acc_lst; }
	}
	
	private string acc_file_path;
	public bool is_new;
	
	public signal void changed(string hash);
	public signal void active_changed();
	
	public Accounts() {
		acc_lst = new ArrayList<Account?>();
		load();
	}
	
	/* load accounts from file */
	private void load() {
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
		acc_file_path = pino_dir + "/accounts.xml";
		var acc_file = File.new_for_path(acc_file_path);
		
		if(!acc_file.query_exists(null)) {
			//var pref_stream = pref_file.create(FileCreateFlags.NONE, null);
			is_new = true;
			return;
		}
		
		//reading content
		string content;
		{
			var stream = new DataInputStream(acc_file.read(null));
			content = stream.read_until("", null, null);
		}
		
		parse(content);
	}
	
	/* parse xml file */
	private void parse(string data) {
		Xml.Doc* xmlDoc = Parser.parse_memory(data, (int)data.size());
		Xml.Node* rootNode = xmlDoc->get_root_element();
		
		for(Xml.Node* iter = rootNode->children; iter != null; iter = iter->next) {
			if(iter->type != ElementType.ELEMENT_NODE)
				continue;
			
			if(iter->name == "account") {
				if(iter->children != null) {
					Account acc = new Account();
					
					Xml.Node *iter_in;
				    
				    for(iter_in = iter->children->next; iter_in != null; iter_in = iter_in->next) {
				    	if(iter_in->is_text() != 1) {
				    		switch(iter_in->name) {
				    			case "login":
				    				acc.login = iter_in->get_content();
				    				break;
				    			
				    			case "password":
				    				acc.password = iter_in->get_content();
				    				break;
				    			
				    			case "service":
				    				acc.service = iter_in->get_content();
				    				break;
				    			
				    			case "proxy":
				    				acc.proxy = iter_in->get_content();
				    				break;
				    			
				    			case "active":
				    				acc.active = iter_in->get_content().to_bool();
				    				break;
				    		}
				    	}
				    }
				    delete iter_in;
				    acc_lst.add(acc);
				}
			}
		}
	}
	
	/* save accounts to the file */
	public void write() {
		Xml.Doc* xmldoc = new Xml.Doc("1.0");
		Xml.Ns* ns = new Xml.Ns(null, null, null);
		ns->type = Xml.ElementType.ELEMENT_NODE;
		Xml.Node* root = new Xml.Node(ns, "accounts");
		xmldoc->set_root_element(root);
		
		root->add_content("\n");
		
		foreach(Account acc in acc_lst) {
			Xml.Node* iter;
			iter = root->new_child(ns, "account");
			
			iter->add_content("\n\t");
			iter->new_text_child(ns, "login", acc.login);
			iter->add_content("\n\t");
			iter->new_text_child(ns, "password", acc.password);
			iter->add_content("\n\t");
			iter->new_text_child(ns, "service", acc.service);
			iter->add_content("\n\t");
			iter->new_text_child(ns, "proxy", acc.proxy);
			iter->add_content("\n\t");
			iter->new_text_child(ns, "active", acc.active.to_string());
			iter->add_content("\n");
			root->add_content("\n");
		}
		
		//write this document to the accounts file
		var stream = FileStream.open(acc_file_path, "w");
		xmldoc->dump(stream);
	}
	
	/* return current account */
	public Account? get_current_account() {
		foreach(Account acc in acc_lst) {
			if(acc.active)
				return acc;
		}
		
		//return first
		if(acc_lst.size > 0) {
			var acc = acc_lst.get(0);
			acc.active = true;
			write();
			return acc;
		}
		else
			return null;
	}
	
	/* add new account */
	public void add_account(Account acc) {
		acc_lst.add(acc);
		//write();
	}
	
	/* delete account by index */
	public void delete_account(string hash) {
		acc_lst.remove(get_by_hash(hash));
	}
	
	/* set one active account */
	public void set_active_account(string hash) {
		foreach(Account acc in acc_lst) {
			acc.active = false;
		}
		
		get_by_hash(hash).active = true;
		
		active_changed(); // send signal
	}
	
	/* changing account */
	public void change_account(int index, Account acc) {
		acc_lst.set(index, acc);
	}
	
	/* get account by login+service+proxy */
	public Account get_by_hash(string hash) {
		foreach(Account acc in acc_lst) {
			if(acc.login + acc.service + acc.proxy == hash)
				return acc;
		}
		
		return null;
	}
}

}
