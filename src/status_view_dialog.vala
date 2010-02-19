/* status_view_dialog.vala
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
using Auth;
using RestAPI;

/* view conversation from bottom to top one */
public class StatusViewDialog : Dialog {
	
	public StatusViewDialog(Window parent, Accounts _accounts, Template template,
	Status _status) {
		
		set_transient_for(parent);
		set_title(_("Conversation"));
		modal = false;
		has_separator = false;
		set_size_request(300, 400);
		
		var view = new StatusViewList(parent, _accounts, _status, template);
		
		vbox.pack_start(view, true, true, 0);
		
		add_button(STOCK_CLOSE, ResponseType.CLOSE);
		response.connect(response_act);
		
		var p_parent = (MainWindow)parent;
		signals_setup(p_parent, view);
		
		show_all();
		
		set_transient_for(parent);
		
		view.update();
	}
	
	private void signals_setup(MainWindow p_parent, StatusViewList view) {
		view.nickto.connect((screen_name) => {
			p_parent.re_tweet.set_nickto(screen_name);
		});
		view.retweet.connect((status) => {
			p_parent.re_tweet.set_state_retweet(status);
		});
		view.directreply.connect((screen_name) => {
			p_parent.re_tweet.set_state_directreply(screen_name);
		});
		view.replyto.connect((status) => {
			p_parent.re_tweet.set_state_reply(status);
		});
		view.deleted.connect((msg) => {
			p_parent.statusbar.set_status(StatusbarSmart.StatusType.DATA_SENT, msg);
		});
	}
	
	private void response_act(int resp_id) {
		switch(resp_id) {
			case ResponseType.CLOSE:
				close();
				break;
		}
	}
}
