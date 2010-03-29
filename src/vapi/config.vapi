/* config.vapi
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

[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "config.h")]
namespace Config
{
	public const string GETTEXT_PACKAGE;
	public const string APPNAME;
	public const string LOCALE_DIR;
	public const string APP_VERSION;
	public const string LOGO_PATH;
	public const string LOGO_FRESH_PATH;
	public const string MENTIONS_PATH;
	public const string MENTIONS_FRESH_PATH;
	public const string TIMELINE_PATH;
	public const string TIMELINE_FRESH_PATH;
	public const string DIRECT_PATH;
	public const string DIRECT_FRESH_PATH;
	public const string FAVORITE_PATH;
	public const string FAVORITE_NO_PATH;
	public const string PROGRESS_PATH;
	public const string DIRECT_REPLY_PATH;
	public const string REPLY_PATH;
	public const string RETWEET_PATH;
	public const string DELETE_PATH;
	public const string USERPIC_PATH;
	public const string TEMPLATES_PATH;
	public const string AUTHORS;
	
	public const string CONS_KEY;
	public const string CONS_SEC;
}

namespace Gtk
{
  [CCode (cprefix = "GTKSPELL_ERROR_", cheader_filename = "gtkspell/gtkspell.h")]
  public errordomain SpeelError
  {
    ERROR_BACKEND
  }

  [Compact]
  [CCode (cheader_filename = "gtkspell/gtkspell.h", free_function = "")]
  public class Spell
  {
    [CCode (cname = "gtkspell_new_attach")]
    public Spell.attach (TextView view, string? lang) throws GLib.Error;
    [CCode (cname = "gtkspell_get_from_text_view")]
    public static Spell get_from_text_view (TextView view);
    [CCode (cname = "gtkspell_detach")]
    public void detach ();
    [CCode (cname = "gtkspell_set_language")]
    public bool set_language (string lang) throws GLib.Error;
    [CCode (cname = "gtkspell_recheck_all")]
    public void recheck_all ();
  }
}

/*
[CCode (cheader_filename = "sha1.h")]
namespace SHA1
{
  [CCode (cname = "_oauth_hmac_sha1")]
  public void hmac (string key, string message, out uchar[] output);
}
*/
