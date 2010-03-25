/*
 * OAuth client implementation using libsoup.
 *
 * Copyright (C) 2009 Mark Lee <oauth@lazymalevolence.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *
 * Author : Mark Lee <oauth@lazymalevolence.com>
 */

using Soup;

namespace OAuth
{
  const string VERSION = "1.0";
  public enum SignatureMethod
  {
    UNKNOWN = 0,
    PLAINTEXT,
    HMAC_SHA1,
    RSA_SHA1
  }
  public class Client : Object
  {
    private Session _session;
    public Session session
    {
      get
      {
        return this._session;
      }
      construct
      {
        this._session = value;
      }
    }
    public string timestamp
    {
      owned get
      {
        time_t ts = time_t ();
        return ((long)ts).to_string ();
      }
    }
    public string nonce
    {
      owned get
      {
        return Random.next_int ().to_string ();
      }
    }
    private HashTable<string,string> _request_token;
    public HashTable<string,string> request_token
    {
      get
      {
        return this._request_token;
      }
    }
    private HashTable<string,string> _access_token;
    public HashTable<string,string> access_token
    {
      get
      {
        return this._access_token;
      }
    }
    private string _consumer_key;
    public string consumer_key
    {
      get
      {
        return this._consumer_key;
      }
      construct
      {
        this._consumer_key = value;
      }
    }
    private string _consumer_secret;
    public string consumer_secret
    {
      construct
      {
        this._consumer_secret = value;
      }
    }
    private SignatureMethod _signature_method;
    private string _signature_method_str;
    public SignatureMethod signature_method
    {
      get
      {
        return this._signature_method;
      }
      construct
      {
        this._signature_method = value;
        this._signature_method_str = signature_method_to_string (value);
      }
    }
    
  public Client(string __consumer_key, string __consumer_secret,
    SignatureMethod __signature_method, Session __session) {
      
    _consumer_key = __consumer_key;
    _consumer_secret = __consumer_secret;
    _signature_method = __signature_method;
    _session = __session;
  }
    
    public static string
    signature_method_to_string (SignatureMethod method)
    {
      string result = null;
      switch (method)
      {
        case SignatureMethod.PLAINTEXT:
          result = "PLAINTEXT";
          break;
        case SignatureMethod.HMAC_SHA1:
          result = "HMAC-SHA1";
          break;
        case SignatureMethod.RSA_SHA1:
          result = "RSA-SHA1";
          break;
        default:
          result = "HMAC-SHA1";
          break;
      }
      return result;
    }
    public static SignatureMethod
    string_to_signature_method (string repr)
    {
      SignatureMethod result;
      switch (repr)
      {
        case "PLAINTEXT":
          result = SignatureMethod.PLAINTEXT;
          break;
        case "HMAC-SHA1":
          result = SignatureMethod.HMAC_SHA1;
          break;
        case "RSA-SHA1":
          result = SignatureMethod.RSA_SHA1;
          break;
        default:
          result = SignatureMethod.HMAC_SHA1;
          break;
      }
      return result;
    }
    /**
     * Conforms to 5.1, "Parameter Encoding".
     * (Note: Soup.form_encode_hash does not conform.)
     */
    public string
    encode_parameters (HashTable<string,string> input)
    {
      string encoded = "";
      List<unowned string> keys = input.get_keys ();
      keys.sort ((CompareFunc)strcmp);
      foreach (unowned string key in keys)
      {
        unowned string? val = input.lookup (key);
        if (val == null)
        {
          debug ("key (%s) is null", key);
          continue;
        }
        if (encoded.len () != 0)
        {
          encoded += "&";
        }
        encoded += URI.encode (key, "&=") + "=" + URI.encode (val, "&=");
      }
      return encoded;
    }
    /**
     * Conforms to Section 9, "Signing Requests".
     */
    public string
    generate_signature (string method, string uri, string token_secret,
                        HashTable<string,string> sig_params)
    {
      // 9.1. Signature Base String
      string sig_base;
      // 9.1.1. Normalize Request Parameters
      // FIXME
      string request_params = this.encode_parameters (sig_params);
      debug ("params: %s", request_params);
      // 9.1.2. Construct Request URL
      URI soup_uri = new URI (uri);
      soup_uri.set_host (soup_uri.host.down ());
      soup_uri.query = null;
      soup_uri.fragment = null;
      string request_uri = soup_uri.to_string (false);
      // 9.1.3. Concatenate Request Elements
      sig_base = "%s&%s&%s".printf (method, URI.encode (request_uri, null),
                                    URI.encode (request_params, "=&"));
      string secrets = "%s&%s".printf (URI.encode (this._consumer_secret, null),
                                       URI.encode (token_secret, null));
      debug ("Signature Base: %s", sig_base);
      string signature = null;
      switch (this._signature_method)
      {
        case SignatureMethod.HMAC_SHA1: // 9.2
          uchar[] hmac;
          debug ("secrets: %li; sig: %li", secrets.len (), sig_base.len ());
          SHA1.hmac (secrets, sig_base, out hmac);
          debug ("hmac: %d", hmac.length);
          assert (hmac.length == 20);
          signature = Base64.encode (hmac);
          break;
        case SignatureMethod.RSA_SHA1: // 9.3
          critical ("Not Implemented.");
          break;
        case SignatureMethod.PLAINTEXT: // 9.4
          signature = secrets;
          break;
      }
      debug ("signature generated: %s", signature);
      return signature;
    }
    public HashTable<string,string>
    generate_params (string method, string uri,
                     HashTable<string,string>? extra=null)
    {
      HashTable<string,string> result;
      string oauth_token_secret;
      string signature;
      if (extra == null)
      {
        result = new HashTable<string,string> (str_hash, str_equal);
      }
      else
      {
        result = extra;
      }
      result.replace ("oauth_consumer_key", this._consumer_key);
      result.replace ("oauth_signature_method", this._signature_method_str);
      result.replace ("oauth_version", VERSION);
      if (this._request_token == null)
      {
        oauth_token_secret = "";
      }
      else
      {
        if (this._access_token == null)
        {
          oauth_token_secret = this._request_token.lookup ("oauth_token_secret");
          result.replace ("oauth_token",
                          this._request_token.lookup ("oauth_token"));
        }
        else
        {
          oauth_token_secret = this._access_token.lookup ("oauth_token_secret");
          result.replace ("oauth_token",
                          this._access_token.lookup ("oauth_token"));
        }
      }
      result.replace ("oauth_timestamp", this.timestamp);
      result.replace ("oauth_nonce", this.nonce);
      signature = this.generate_signature (method, uri, oauth_token_secret,
                                           result);
      result.replace ("oauth_signature", signature);
      return result;
    }
    public void
    fetch_request_token (string method, string uri,
                         HashTable<string,string>? extra_params=null)
    {
      HashTable<string,string> request_params;
      Message msg;
      string encoded;
      
      request_params = this.generate_params (method, uri, extra_params);
      msg = new Message (method, uri);
      encoded = this.encode_parameters (request_params);
      debug ("encoded params: %s", encoded);
      msg.request_body.append (MemoryUse.COPY, (void*)encoded, encoded.len ());
      this._session.send_message (msg);
      warning((string)msg.response_body.flatten().data);
      this._request_token = form_decode ((string)msg.response_body.flatten().data);
    }
    public string
    authorize_request_token (string uri)
    {
      string full_uri;
      if (uri.contains ("%s"))
      {
        full_uri = uri.printf (this._request_token.lookup ("oauth_token"));
      }
      else
      {
        full_uri = uri;
      }
      return full_uri;
    }
    public void
    fetch_access_token (string method, string uri, string pin)
    {
      HashTable<string,string> params;
      Message msg;
      
      HashTable<string, string> extra = new HashTable<string,string> (str_hash, str_equal);
      extra.insert("oauth_verifier", pin);
      params = this.generate_params (method, uri, extra);
      msg = form_request_new_from_hash (method, uri, params);
      this._session.send_message (msg);
      warning((string)msg.response_body.flatten().data);
      this._access_token = form_decode ((string)msg.response_body.flatten().data);
    }
    public string generate_authorization (string method, string uri, string realm)
    {
      string header = "OAuth";
      HashTable<string,string> params;

      params = this.generate_params (method, uri);
      params.insert ("realm", realm);
      foreach (weak string key in params.get_keys ())
      {
        if (header.len () != 5)
        {
          header += ",";
        }
        string value = URI.encode (params.lookup (key), null);
        header += " %s=\"%s\"".printf (URI.encode (key, null), value);
      }
      return header;
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
