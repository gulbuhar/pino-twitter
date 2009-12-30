
#include <glib.h>
#include <glib-object.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <gee.h>
#include <libsoup/soup.h>
#include <libxml/parser.h>
#include <libxml/tree.h>
#include <locale.h>
#include <gobject/gvaluecollector.h>


#define TYPE_STATUS (status_get_type ())
#define STATUS(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_STATUS, Status))
#define STATUS_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_STATUS, StatusClass))
#define IS_STATUS(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_STATUS))
#define IS_STATUS_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_STATUS))
#define STATUS_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_STATUS, StatusClass))

typedef struct _Status Status;
typedef struct _StatusClass StatusClass;
typedef struct _StatusPrivate StatusPrivate;
#define _g_free0(var) (var = (g_free (var), NULL))
typedef struct _ParamSpecStatus ParamSpecStatus;

#define TYPE_TWITTER_INTERFACE (twitter_interface_get_type ())
#define TWITTER_INTERFACE(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_TWITTER_INTERFACE, TwitterInterface))
#define TWITTER_INTERFACE_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_TWITTER_INTERFACE, TwitterInterfaceClass))
#define IS_TWITTER_INTERFACE(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_TWITTER_INTERFACE))
#define IS_TWITTER_INTERFACE_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_TWITTER_INTERFACE))
#define TWITTER_INTERFACE_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_TWITTER_INTERFACE, TwitterInterfaceClass))

typedef struct _TwitterInterface TwitterInterface;
typedef struct _TwitterInterfaceClass TwitterInterfaceClass;
typedef struct _TwitterInterfacePrivate TwitterInterfacePrivate;

#define TWITTER_INTERFACE_TYPE_REPLY (twitter_interface_reply_get_type ())
#define _g_object_unref0(var) ((var == NULL) ? NULL : (var = (g_object_unref (var), NULL)))
#define _status_unref0(var) ((var == NULL) ? NULL : (var = (status_unref (var), NULL)))

struct _Status {
	GTypeInstance parent_instance;
	volatile int ref_count;
	StatusPrivate * priv;
	gint id;
	char* text;
	struct tm created_at;
	char* user_name;
	char* user_screen_name;
	char* user_avatar;
	gboolean is_new;
};

struct _StatusClass {
	GTypeClass parent_class;
	void (*finalize) (Status *self);
};

struct _ParamSpecStatus {
	GParamSpec parent_instance;
};

struct _TwitterInterface {
	GObject parent_instance;
	TwitterInterfacePrivate * priv;
};

struct _TwitterInterfaceClass {
	GObjectClass parent_class;
};

struct _TwitterInterfacePrivate {
	GeeArrayList* _friends;
	char* login;
	char* password;
	char* friendsUrl;
	char* statusUpdateUrl;
};

typedef enum  {
	TWITTER_INTERFACE_REPLY_ERROR_TIMEOUT,
	TWITTER_INTERFACE_REPLY_ERROR_401,
	TWITTER_INTERFACE_REPLY_ERROR_UNKNOWN,
	TWITTER_INTERFACE_REPLY_OK
} TwitterInterfaceReply;


static gpointer status_parent_class = NULL;
static gpointer twitter_interface_parent_class = NULL;

gpointer status_ref (gpointer instance);
void status_unref (gpointer instance);
GParamSpec* param_spec_status (const gchar* name, const gchar* nick, const gchar* blurb, GType object_type, GParamFlags flags);
void value_set_status (GValue* value, gpointer v_object);
gpointer value_get_status (const GValue* value);
GType status_get_type (void);
enum  {
	STATUS_DUMMY_PROPERTY
};
Status* status_new (void);
Status* status_construct (GType object_type);
static void status_finalize (Status* obj);
GType twitter_interface_get_type (void);
#define TWITTER_INTERFACE_GET_PRIVATE(o) (G_TYPE_INSTANCE_GET_PRIVATE ((o), TYPE_TWITTER_INTERFACE, TwitterInterfacePrivate))
enum  {
	TWITTER_INTERFACE_DUMMY_PROPERTY,
	TWITTER_INTERFACE_FRIENDS
};
GType twitter_interface_reply_get_type (void);
TwitterInterface* twitter_interface_new (void);
TwitterInterface* twitter_interface_construct (GType object_type);
void twitter_interface_set_auth (TwitterInterface* self, const char* _login, const char* _password);
TwitterInterface* twitter_interface_new_with_auth (const char* _login, const char* _password);
TwitterInterface* twitter_interface_construct_with_auth (GType object_type, const char* _login, const char* _password);
static void _lambda0_ (SoupSessionAsync* sess, SoupMessage* msg, SoupAuth* auth, gboolean retrying, TwitterInterface* self);
static void __lambda0__soup_session_authenticate (SoupSessionAsync* _sender, SoupMessage* msg, SoupAuth* auth, gboolean retrying, gpointer self);
static void twitter_interface_parse_xml (TwitterInterface* self, const char* data);
TwitterInterfaceReply twitter_interface_syncFriends (TwitterInterface* self);
static void _lambda1_ (SoupSessionAsync* sess, SoupMessage* msg, SoupAuth* auth, gboolean retrying, TwitterInterface* self);
static void __lambda1__soup_session_authenticate (SoupSessionAsync* _sender, SoupMessage* msg, SoupAuth* auth, gboolean retrying, gpointer self);
TwitterInterfaceReply twitter_interface_updateStatus (TwitterInterface* self, const char* status);
static gint twitter_interface_tz_delta (TwitterInterface* self);
GeeArrayList* twitter_interface_get_friends (TwitterInterface* self);
static void twitter_interface_finalize (GObject* obj);
static void twitter_interface_get_property (GObject * object, guint property_id, GValue * value, GParamSpec * pspec);
static int _vala_strcmp0 (const char * str1, const char * str2);



#line 5 "twitter_interface.vala"
Status* status_construct (GType object_type) {
#line 135 "twitter_interface.c"
	Status* self;
	self = (Status*) g_type_create_instance (object_type);
	return self;
}


#line 5 "twitter_interface.vala"
Status* status_new (void) {
#line 5 "twitter_interface.vala"
	return status_construct (TYPE_STATUS);
#line 146 "twitter_interface.c"
}


static void value_status_init (GValue* value) {
	value->data[0].v_pointer = NULL;
}


static void value_status_free_value (GValue* value) {
	if (value->data[0].v_pointer) {
		status_unref (value->data[0].v_pointer);
	}
}


static void value_status_copy_value (const GValue* src_value, GValue* dest_value) {
	if (src_value->data[0].v_pointer) {
		dest_value->data[0].v_pointer = status_ref (src_value->data[0].v_pointer);
	} else {
		dest_value->data[0].v_pointer = NULL;
	}
}


static gpointer value_status_peek_pointer (const GValue* value) {
	return value->data[0].v_pointer;
}


static gchar* value_status_collect_value (GValue* value, guint n_collect_values, GTypeCValue* collect_values, guint collect_flags) {
	if (collect_values[0].v_pointer) {
		Status* object;
		object = collect_values[0].v_pointer;
		if (object->parent_instance.g_class == NULL) {
			return g_strconcat ("invalid unclassed object pointer for value type `", G_VALUE_TYPE_NAME (value), "'", NULL);
		} else if (!g_value_type_compatible (G_TYPE_FROM_INSTANCE (object), G_VALUE_TYPE (value))) {
			return g_strconcat ("invalid object type `", g_type_name (G_TYPE_FROM_INSTANCE (object)), "' for value type `", G_VALUE_TYPE_NAME (value), "'", NULL);
		}
		value->data[0].v_pointer = status_ref (object);
	} else {
		value->data[0].v_pointer = NULL;
	}
	return NULL;
}


static gchar* value_status_lcopy_value (const GValue* value, guint n_collect_values, GTypeCValue* collect_values, guint collect_flags) {
	Status** object_p;
	object_p = collect_values[0].v_pointer;
	if (!object_p) {
		return g_strdup_printf ("value location for `%s' passed as NULL", G_VALUE_TYPE_NAME (value));
	}
	if (!value->data[0].v_pointer) {
		*object_p = NULL;
	} else if (collect_flags && G_VALUE_NOCOPY_CONTENTS) {
		*object_p = value->data[0].v_pointer;
	} else {
		*object_p = status_ref (value->data[0].v_pointer);
	}
	return NULL;
}


GParamSpec* param_spec_status (const gchar* name, const gchar* nick, const gchar* blurb, GType object_type, GParamFlags flags) {
	ParamSpecStatus* spec;
	g_return_val_if_fail (g_type_is_a (object_type, TYPE_STATUS), NULL);
	spec = g_param_spec_internal (G_TYPE_PARAM_OBJECT, name, nick, blurb, flags);
	G_PARAM_SPEC (spec)->value_type = object_type;
	return G_PARAM_SPEC (spec);
}


gpointer value_get_status (const GValue* value) {
	g_return_val_if_fail (G_TYPE_CHECK_VALUE_TYPE (value, TYPE_STATUS), NULL);
	return value->data[0].v_pointer;
}


void value_set_status (GValue* value, gpointer v_object) {
	Status* old;
	g_return_if_fail (G_TYPE_CHECK_VALUE_TYPE (value, TYPE_STATUS));
	old = value->data[0].v_pointer;
	if (v_object) {
		g_return_if_fail (G_TYPE_CHECK_INSTANCE_TYPE (v_object, TYPE_STATUS));
		g_return_if_fail (g_value_type_compatible (G_TYPE_FROM_INSTANCE (v_object), G_VALUE_TYPE (value)));
		value->data[0].v_pointer = v_object;
		status_ref (value->data[0].v_pointer);
	} else {
		value->data[0].v_pointer = NULL;
	}
	if (old) {
		status_unref (old);
	}
}


static void status_class_init (StatusClass * klass) {
	status_parent_class = g_type_class_peek_parent (klass);
	STATUS_CLASS (klass)->finalize = status_finalize;
}


static void status_instance_init (Status * self) {
	struct tm _tmp0_ = {0};
	self->created_at = (memset (&_tmp0_, 0, sizeof (struct tm)), _tmp0_);
	self->is_new = FALSE;
	self->ref_count = 1;
}


static void status_finalize (Status* obj) {
	Status * self;
	self = STATUS (obj);
	_g_free0 (self->text);
	_g_free0 (self->user_name);
	_g_free0 (self->user_screen_name);
	_g_free0 (self->user_avatar);
}


GType status_get_type (void) {
	static GType status_type_id = 0;
	if (status_type_id == 0) {
		static const GTypeValueTable g_define_type_value_table = { value_status_init, value_status_free_value, value_status_copy_value, value_status_peek_pointer, "p", value_status_collect_value, "p", value_status_lcopy_value };
		static const GTypeInfo g_define_type_info = { sizeof (StatusClass), (GBaseInitFunc) NULL, (GBaseFinalizeFunc) NULL, (GClassInitFunc) status_class_init, (GClassFinalizeFunc) NULL, NULL, sizeof (Status), 0, (GInstanceInitFunc) status_instance_init, &g_define_type_value_table };
		static const GTypeFundamentalInfo g_define_type_fundamental_info = { (G_TYPE_FLAG_CLASSED | G_TYPE_FLAG_INSTANTIATABLE | G_TYPE_FLAG_DERIVABLE | G_TYPE_FLAG_DEEP_DERIVABLE) };
		status_type_id = g_type_register_fundamental (g_type_fundamental_next (), "Status", &g_define_type_info, &g_define_type_fundamental_info, 0);
	}
	return status_type_id;
}


gpointer status_ref (gpointer instance) {
	Status* self;
	self = instance;
	g_atomic_int_inc (&self->ref_count);
	return instance;
}


void status_unref (gpointer instance) {
	Status* self;
	self = instance;
	if (g_atomic_int_dec_and_test (&self->ref_count)) {
		STATUS_GET_CLASS (self)->finalize (self);
		g_type_free_instance ((GTypeInstance *) self);
	}
}



GType twitter_interface_reply_get_type (void) {
	static GType twitter_interface_reply_type_id = 0;
	if (G_UNLIKELY (twitter_interface_reply_type_id == 0)) {
		static const GEnumValue values[] = {{TWITTER_INTERFACE_REPLY_ERROR_TIMEOUT, "TWITTER_INTERFACE_REPLY_ERROR_TIMEOUT", "error-timeout"}, {TWITTER_INTERFACE_REPLY_ERROR_401, "TWITTER_INTERFACE_REPLY_ERROR_401", "error-401"}, {TWITTER_INTERFACE_REPLY_ERROR_UNKNOWN, "TWITTER_INTERFACE_REPLY_ERROR_UNKNOWN", "error-unknown"}, {TWITTER_INTERFACE_REPLY_OK, "TWITTER_INTERFACE_REPLY_OK", "ok"}, {0, NULL, NULL}};
		twitter_interface_reply_type_id = g_enum_register_static ("TwitterInterfaceReply", values);
	}
	return twitter_interface_reply_type_id;
}


#line 40 "twitter_interface.vala"
TwitterInterface* twitter_interface_construct (GType object_type) {
#line 310 "twitter_interface.c"
	TwitterInterface * self;
#line 40 "twitter_interface.vala"
	self = (TwitterInterface*) g_object_new (object_type, NULL);
#line 314 "twitter_interface.c"
	return self;
}


#line 40 "twitter_interface.vala"
TwitterInterface* twitter_interface_new (void) {
#line 40 "twitter_interface.vala"
	return twitter_interface_construct (TYPE_TWITTER_INTERFACE);
#line 323 "twitter_interface.c"
}


#line 42 "twitter_interface.vala"
TwitterInterface* twitter_interface_construct_with_auth (GType object_type, const char* _login, const char* _password) {
#line 329 "twitter_interface.c"
	TwitterInterface * self;
#line 42 "twitter_interface.vala"
	g_return_val_if_fail (_login != NULL, NULL);
#line 42 "twitter_interface.vala"
	g_return_val_if_fail (_password != NULL, NULL);
#line 42 "twitter_interface.vala"
	self = (TwitterInterface*) g_object_new (object_type, NULL);
#line 44 "twitter_interface.vala"
	twitter_interface_set_auth (self, _login, _password);
#line 339 "twitter_interface.c"
	return self;
}


#line 42 "twitter_interface.vala"
TwitterInterface* twitter_interface_new_with_auth (const char* _login, const char* _password) {
#line 42 "twitter_interface.vala"
	return twitter_interface_construct_with_auth (TYPE_TWITTER_INTERFACE, _login, _password);
#line 348 "twitter_interface.c"
}


#line 47 "twitter_interface.vala"
void twitter_interface_set_auth (TwitterInterface* self, const char* _login, const char* _password) {
#line 354 "twitter_interface.c"
	char* _tmp0_;
	char* _tmp1_;
#line 47 "twitter_interface.vala"
	g_return_if_fail (self != NULL);
#line 47 "twitter_interface.vala"
	g_return_if_fail (_login != NULL);
#line 47 "twitter_interface.vala"
	g_return_if_fail (_password != NULL);
#line 49 "twitter_interface.vala"
	self->priv->login = (_tmp0_ = g_strdup (_login), _g_free0 (self->priv->login), _tmp0_);
#line 50 "twitter_interface.vala"
	self->priv->password = (_tmp1_ = g_strdup (_password), _g_free0 (self->priv->password), _tmp1_);
#line 367 "twitter_interface.c"
}


static void _lambda0_ (SoupSessionAsync* sess, SoupMessage* msg, SoupAuth* auth, gboolean retrying, TwitterInterface* self) {
	g_return_if_fail (sess != NULL);
	g_return_if_fail (msg != NULL);
	g_return_if_fail (auth != NULL);
#line 63 "twitter_interface.vala"
	if (retrying) {
#line 377 "twitter_interface.c"
		return;
	}
#line 65 "twitter_interface.vala"
	soup_auth_authenticate (auth, self->priv->login, self->priv->password);
#line 382 "twitter_interface.c"
}


static void __lambda0__soup_session_authenticate (SoupSessionAsync* _sender, SoupMessage* msg, SoupAuth* auth, gboolean retrying, gpointer self) {
	_lambda0_ (_sender, msg, auth, retrying, self);
}


#line 53 "twitter_interface.vala"
TwitterInterfaceReply twitter_interface_syncFriends (TwitterInterface* self) {
#line 393 "twitter_interface.c"
	TwitterInterfaceReply result;
	SoupSessionAsync* session;
	SoupMessage* message;
#line 53 "twitter_interface.vala"
	g_return_val_if_fail (self != NULL, 0);
#line 55 "twitter_interface.vala"
	g_signal_emit_by_name (self, "updating");
#line 401 "twitter_interface.c"
	session = (SoupSessionAsync*) soup_session_async_new ();
#line 58 "twitter_interface.vala"
	g_object_set ((SoupSession*) session, "timeout", (guint) 10, NULL);
#line 405 "twitter_interface.c"
	message = soup_message_new ("GET", self->priv->friendsUrl);
#line 62 "twitter_interface.vala"
	g_signal_connect_object ((SoupSession*) session, "authenticate", (GCallback) __lambda0__soup_session_authenticate, self, 0);
#line 70 "twitter_interface.vala"
	switch (soup_session_send_message ((SoupSession*) session, message)) {
#line 411 "twitter_interface.c"
		case 401:
		{
			result = TWITTER_INTERFACE_REPLY_ERROR_401;
			_g_object_unref0 (session);
			_g_object_unref0 (message);
			return result;
		}
		case 2:
		{
			result = TWITTER_INTERFACE_REPLY_ERROR_TIMEOUT;
			_g_object_unref0 (session);
			_g_object_unref0 (message);
			return result;
		}
		case 200:
		{
#line 77 "twitter_interface.vala"
			twitter_interface_parse_xml (self, message->response_body->data);
#line 78 "twitter_interface.vala"
			g_signal_emit_by_name (self, "updated");
#line 432 "twitter_interface.c"
			result = TWITTER_INTERFACE_REPLY_OK;
			_g_object_unref0 (session);
			_g_object_unref0 (message);
			return result;
		}
		default:
		{
			result = TWITTER_INTERFACE_REPLY_ERROR_UNKNOWN;
			_g_object_unref0 (session);
			_g_object_unref0 (message);
			return result;
		}
	}
	_g_object_unref0 (session);
	_g_object_unref0 (message);
}


static glong string_get_length (const char* self) {
	glong result;
	g_return_val_if_fail (self != NULL, 0L);
	result = g_utf8_strlen (self, -1);
	return result;
}


static void _lambda1_ (SoupSessionAsync* sess, SoupMessage* msg, SoupAuth* auth, gboolean retrying, TwitterInterface* self) {
	g_return_if_fail (sess != NULL);
	g_return_if_fail (msg != NULL);
	g_return_if_fail (auth != NULL);
#line 106 "twitter_interface.vala"
	if (retrying) {
#line 465 "twitter_interface.c"
		return;
	}
#line 108 "twitter_interface.vala"
	soup_auth_authenticate (auth, "troorl", "troorl_troorl");
#line 470 "twitter_interface.c"
}


static void __lambda1__soup_session_authenticate (SoupSessionAsync* _sender, SoupMessage* msg, SoupAuth* auth, gboolean retrying, gpointer self) {
	_lambda1_ (_sender, msg, auth, retrying, self);
}


#line 89 "twitter_interface.vala"
TwitterInterfaceReply twitter_interface_updateStatus (TwitterInterface* self, const char* status) {
#line 481 "twitter_interface.c"
	TwitterInterfaceReply result;
	SoupSessionAsync* session;
	SoupMessage* message;
	char* req_body;
#line 89 "twitter_interface.vala"
	g_return_val_if_fail (self != NULL, 0);
#line 89 "twitter_interface.vala"
	g_return_val_if_fail (status != NULL, 0);
#line 91 "twitter_interface.vala"
	g_signal_emit_by_name (self, "send-status");
#line 492 "twitter_interface.c"
	session = (SoupSessionAsync*) soup_session_async_new ();
	message = soup_message_new ("POST", self->priv->statusUpdateUrl);
	req_body = g_strdup (soup_form_encode ("status", status, NULL));
#line 97 "twitter_interface.vala"
	soup_message_set_request (message, "application/x-www-form-urlencoded", SOUP_MEMORY_COPY, req_body, (gsize) string_get_length (req_body));
#line 101 "twitter_interface.vala"
	soup_message_headers_append (message->request_headers, "X-Twitter-Client", "pino");
#line 102 "twitter_interface.vala"
	soup_message_headers_append (message->request_headers, "X-Twitter-Client-Version", "0.1.0");
#line 103 "twitter_interface.vala"
	soup_message_headers_append (message->request_headers, "X-Twitter-Client-URL", "http://pino-twitter.googlecode.com/files/client_info");
#line 105 "twitter_interface.vala"
	g_signal_connect_object ((SoupSession*) session, "authenticate", (GCallback) __lambda1__soup_session_authenticate, self, 0);
#line 112 "twitter_interface.vala"
	switch (soup_session_send_message ((SoupSession*) session, message)) {
#line 508 "twitter_interface.c"
		case 401:
		{
			result = TWITTER_INTERFACE_REPLY_ERROR_401;
			_g_object_unref0 (session);
			_g_object_unref0 (message);
			_g_free0 (req_body);
			return result;
		}
		case 2:
		{
			result = TWITTER_INTERFACE_REPLY_ERROR_TIMEOUT;
			_g_object_unref0 (session);
			_g_object_unref0 (message);
			_g_free0 (req_body);
			return result;
		}
		case 200:
		{
			result = TWITTER_INTERFACE_REPLY_OK;
			_g_object_unref0 (session);
			_g_object_unref0 (message);
			_g_free0 (req_body);
			return result;
		}
		default:
		{
			result = TWITTER_INTERFACE_REPLY_ERROR_UNKNOWN;
			_g_object_unref0 (session);
			_g_object_unref0 (message);
			_g_free0 (req_body);
			return result;
		}
	}
	_g_object_unref0 (session);
	_g_object_unref0 (message);
	_g_free0 (req_body);
}


#line 1955 "glib-2.0.vapi"
static void g_time_local (time_t time, struct tm* result) {
#line 550 "twitter_interface.c"
	struct tm _result_ = {0};
#line 1957 "glib-2.0.vapi"
	localtime_r (&time, &_result_);
#line 554 "twitter_interface.c"
	*result = _result_;
	return;
}


#line 1965 "glib-2.0.vapi"
static char* g_time_format (struct tm *self, const char* format) {
#line 562 "twitter_interface.c"
	char* result;
	gchar* _tmp0_;
	gint buffer_size;
	gint buffer_length1;
	gchar* buffer;
#line 1965 "glib-2.0.vapi"
	g_return_val_if_fail (format != NULL, NULL);
#line 570 "twitter_interface.c"
	buffer = (_tmp0_ = g_new0 (gchar, 64), buffer_length1 = 64, buffer_size = buffer_length1, _tmp0_);
#line 1967 "glib-2.0.vapi"
	strftime (buffer, buffer_length1, format, &(*self));
#line 574 "twitter_interface.c"
	result = g_strdup ((const char*) buffer);
	buffer = (g_free (buffer), NULL);
	return result;
}


#line 125 "twitter_interface.vala"
static gint twitter_interface_tz_delta (TwitterInterface* self) {
#line 583 "twitter_interface.c"
	gint result;
	struct tm _tmp1_;
	struct tm _tmp0_ = {0};
	time_t t;
	struct tm _tmp2_ = {0};
	struct tm time;
	char* sdelta;
#line 125 "twitter_interface.vala"
	g_return_val_if_fail (self != NULL, 0);
#line 593 "twitter_interface.c"
	t = mktime ((_tmp1_ = (memset (&_tmp0_, 0, sizeof (struct tm)), _tmp0_), &_tmp1_));
	time = (g_time_local (t, &_tmp2_), _tmp2_);
	sdelta = g_time_format (&time, "%z");
	result = (atoi (sdelta) / 100) - 1;
	_g_free0 (sdelta);
	return result;
}


static gpointer _g_object_ref0 (gpointer self) {
	return self ? g_object_ref (self) : NULL;
}


#line 135 "twitter_interface.vala"
static void twitter_interface_parse_xml (TwitterInterface* self, const char* data) {
#line 610 "twitter_interface.c"
	GeeArrayList* tmpList;
	xmlDoc* xmlDoc;
	xmlNode* rootNode;
	char* currentLocale;
	gint delta;
	GeeArrayList* _tmp14_;
	GeeArrayList* _tmp15_;
#line 135 "twitter_interface.vala"
	g_return_if_fail (self != NULL);
#line 135 "twitter_interface.vala"
	g_return_if_fail (data != NULL);
#line 622 "twitter_interface.c"
	tmpList = gee_array_list_new (TYPE_STATUS, (GBoxedCopyFunc) status_ref, status_unref, g_direct_equal);
	xmlDoc = xmlParseMemory (data, (gint) string_get_length (data));
	rootNode = xmlDocGetRootElement (xmlDoc);
	currentLocale = g_strdup (setlocale (LC_TIME, NULL));
#line 144 "twitter_interface.vala"
	setlocale (LC_TIME, "C");
#line 629 "twitter_interface.c"
	delta = twitter_interface_tz_delta (self);
	{
		xmlNode* iter;
		iter = rootNode->children;
		{
			gboolean _tmp0_;
			_tmp0_ = TRUE;
#line 148 "twitter_interface.vala"
			while (TRUE) {
#line 148 "twitter_interface.vala"
				if (!_tmp0_) {
#line 148 "twitter_interface.vala"
					iter = iter->next;
#line 643 "twitter_interface.c"
				}
#line 148 "twitter_interface.vala"
				_tmp0_ = FALSE;
#line 148 "twitter_interface.vala"
				if (!(iter != NULL)) {
#line 148 "twitter_interface.vala"
					break;
#line 651 "twitter_interface.c"
				}
#line 150 "twitter_interface.vala"
				if (iter->type != XML_ELEMENT_NODE) {
#line 151 "twitter_interface.vala"
					continue;
#line 657 "twitter_interface.c"
				}
#line 153 "twitter_interface.vala"
				if (_vala_strcmp0 (iter->name, "status") == 0) {
#line 155 "twitter_interface.vala"
					if (iter->children != NULL) {
#line 663 "twitter_interface.c"
						Status* status;
						status = status_new ();
						{
							xmlNode* iter_in;
							iter_in = iter->children->next;
							{
								gboolean _tmp1_;
								_tmp1_ = TRUE;
#line 158 "twitter_interface.vala"
								while (TRUE) {
#line 158 "twitter_interface.vala"
									if (!_tmp1_) {
#line 158 "twitter_interface.vala"
										iter_in = iter_in->next;
#line 678 "twitter_interface.c"
									}
#line 158 "twitter_interface.vala"
									_tmp1_ = FALSE;
#line 158 "twitter_interface.vala"
									if (!(iter_in != NULL)) {
#line 158 "twitter_interface.vala"
										break;
#line 686 "twitter_interface.c"
									}
#line 160 "twitter_interface.vala"
									if (xmlNodeIsText (iter_in) != 1) {
#line 690 "twitter_interface.c"
										GQuark _tmp13_;
										const char* _tmp12_;
										static GQuark _tmp13__label0 = 0;
										static GQuark _tmp13__label1 = 0;
										static GQuark _tmp13__label2 = 0;
										static GQuark _tmp13__label3 = 0;
										_tmp12_ = iter_in->name;
										_tmp13_ = (NULL == _tmp12_) ? 0 : g_quark_from_string (_tmp12_);
										if (_tmp13_ == ((0 != _tmp13__label0) ? _tmp13__label0 : (_tmp13__label0 = g_quark_from_static_string ("id"))))
										do {
#line 167 "twitter_interface.vala"
											status->id = (gint) xmlNodeGetContent (iter_in);
#line 168 "twitter_interface.vala"
											break;
#line 705 "twitter_interface.c"
										} while (0); else if (_tmp13_ == ((0 != _tmp13__label1) ? _tmp13__label1 : (_tmp13__label1 = g_quark_from_static_string ("created_at"))))
										do {
											struct tm _tmp2_ = {0};
											struct tm tmpTime;
											char* _tmp3_;
											time_t tt;
											gint int_t;
											struct tm _tmp4_ = {0};
											tmpTime = (memset (&_tmp2_, 0, sizeof (struct tm)), _tmp2_);
#line 174 "twitter_interface.vala"
											strptime (_tmp3_ = xmlNodeGetContent (iter_in), "%a %b %d %T +0000 %Y", &tmpTime);
#line 717 "twitter_interface.c"
											_g_free0 (_tmp3_);
											tt = mktime (&tmpTime);
											int_t = ((gint) tt) + (delta * 3600);
#line 180 "twitter_interface.vala"
											status->created_at = (g_time_local ((time_t) int_t, &_tmp4_), _tmp4_);
#line 182 "twitter_interface.vala"
											break;
#line 725 "twitter_interface.c"
										} while (0); else if (_tmp13_ == ((0 != _tmp13__label2) ? _tmp13__label2 : (_tmp13__label2 = g_quark_from_static_string ("text"))))
										do {
											char* _tmp5_;
#line 185 "twitter_interface.vala"
											status->text = (_tmp5_ = xmlNodeGetContent (iter_in), _g_free0 (status->text), _tmp5_);
#line 186 "twitter_interface.vala"
											break;
#line 733 "twitter_interface.c"
										} while (0); else if (_tmp13_ == ((0 != _tmp13__label3) ? _tmp13__label3 : (_tmp13__label3 = g_quark_from_static_string ("user"))))
										do {
											{
												xmlNode* iter_user;
												iter_user = iter_in->children->next;
												{
													gboolean _tmp6_;
													_tmp6_ = TRUE;
#line 189 "twitter_interface.vala"
													while (TRUE) {
#line 744 "twitter_interface.c"
														GQuark _tmp11_;
														const char* _tmp10_;
														static GQuark _tmp11__label0 = 0;
														static GQuark _tmp11__label1 = 0;
														static GQuark _tmp11__label2 = 0;
#line 189 "twitter_interface.vala"
														if (!_tmp6_) {
#line 189 "twitter_interface.vala"
															iter_user = iter_user->next;
#line 754 "twitter_interface.c"
														}
#line 189 "twitter_interface.vala"
														_tmp6_ = FALSE;
#line 189 "twitter_interface.vala"
														if (!(iter_user != NULL)) {
#line 189 "twitter_interface.vala"
															break;
#line 762 "twitter_interface.c"
														}
														_tmp10_ = iter_user->name;
														_tmp11_ = (NULL == _tmp10_) ? 0 : g_quark_from_string (_tmp10_);
														if (_tmp11_ == ((0 != _tmp11__label0) ? _tmp11__label0 : (_tmp11__label0 = g_quark_from_static_string ("name"))))
														do {
															char* _tmp7_;
#line 194 "twitter_interface.vala"
															status->user_name = (_tmp7_ = xmlNodeGetContent (iter_user), _g_free0 (status->user_name), _tmp7_);
#line 196 "twitter_interface.vala"
															break;
#line 773 "twitter_interface.c"
														} while (0); else if (_tmp11_ == ((0 != _tmp11__label1) ? _tmp11__label1 : (_tmp11__label1 = g_quark_from_static_string ("screen_name"))))
														do {
															char* _tmp8_;
#line 199 "twitter_interface.vala"
															status->user_screen_name = (_tmp8_ = xmlNodeGetContent (iter_user), _g_free0 (status->user_screen_name), _tmp8_);
#line 200 "twitter_interface.vala"
															break;
#line 781 "twitter_interface.c"
														} while (0); else if (_tmp11_ == ((0 != _tmp11__label2) ? _tmp11__label2 : (_tmp11__label2 = g_quark_from_static_string ("profile_image_url"))))
														do {
															char* _tmp9_;
#line 203 "twitter_interface.vala"
															status->user_avatar = (_tmp9_ = xmlNodeGetContent (iter_user), _g_free0 (status->user_avatar), _tmp9_);
#line 204 "twitter_interface.vala"
															break;
#line 789 "twitter_interface.c"
														} while (0);
													}
												}
											}
#line 207 "twitter_interface.vala"
											break;
#line 796 "twitter_interface.c"
										} while (0);
									}
								}
							}
						}
#line 217 "twitter_interface.vala"
						if (gee_collection_get_size ((GeeCollection*) self->priv->_friends) > 0) {
#line 804 "twitter_interface.c"
							Status* last_status;
							last_status = (Status*) gee_abstract_list_get ((GeeAbstractList*) self->priv->_friends, 0);
#line 220 "twitter_interface.vala"
							if (((gint) mktime (&status->created_at)) > ((gint) mktime (&last_status->created_at))) {
#line 222 "twitter_interface.vala"
								status->is_new = TRUE;
#line 811 "twitter_interface.c"
							}
							_status_unref0 (last_status);
						}
#line 226 "twitter_interface.vala"
						gee_abstract_collection_add ((GeeAbstractCollection*) tmpList, status);
#line 817 "twitter_interface.c"
						_status_unref0 (status);
					}
				}
			}
		}
	}
#line 232 "twitter_interface.vala"
	setlocale (LC_TIME, currentLocale);
#line 234 "twitter_interface.vala"
	gee_abstract_collection_clear ((GeeAbstractCollection*) self->priv->_friends);
#line 235 "twitter_interface.vala"
	self->priv->_friends = (_tmp14_ = NULL, _g_object_unref0 (self->priv->_friends), _tmp14_);
#line 236 "twitter_interface.vala"
	self->priv->_friends = (_tmp15_ = _g_object_ref0 (tmpList), _g_object_unref0 (self->priv->_friends), _tmp15_);
#line 832 "twitter_interface.c"
	_g_object_unref0 (tmpList);
	_g_free0 (currentLocale);
}


GeeArrayList* twitter_interface_get_friends (TwitterInterface* self) {
	GeeArrayList* result;
	g_return_val_if_fail (self != NULL, NULL);
	result = self->priv->_friends;
	return result;
}


static void twitter_interface_class_init (TwitterInterfaceClass * klass) {
	twitter_interface_parent_class = g_type_class_peek_parent (klass);
	g_type_class_add_private (klass, sizeof (TwitterInterfacePrivate));
	G_OBJECT_CLASS (klass)->get_property = twitter_interface_get_property;
	G_OBJECT_CLASS (klass)->finalize = twitter_interface_finalize;
	g_object_class_install_property (G_OBJECT_CLASS (klass), TWITTER_INTERFACE_FRIENDS, g_param_spec_object ("friends", "friends", "friends", GEE_TYPE_ARRAY_LIST, G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK | G_PARAM_STATIC_BLURB | G_PARAM_READABLE));
	g_signal_new ("updating", TYPE_TWITTER_INTERFACE, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__VOID, G_TYPE_NONE, 0);
	g_signal_new ("send_status", TYPE_TWITTER_INTERFACE, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__VOID, G_TYPE_NONE, 0);
	g_signal_new ("updated", TYPE_TWITTER_INTERFACE, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__VOID, G_TYPE_NONE, 0);
}


static void twitter_interface_instance_init (TwitterInterface * self) {
	self->priv = TWITTER_INTERFACE_GET_PRIVATE (self);
	self->priv->_friends = gee_array_list_new (TYPE_STATUS, (GBoxedCopyFunc) status_ref, status_unref, g_direct_equal);
	self->priv->friendsUrl = g_strdup ("http://twitter.com/statuses/friends_timeline.xml");
	self->priv->statusUpdateUrl = g_strdup ("http://twitter.com/statuses/update.xml");
}


static void twitter_interface_finalize (GObject* obj) {
	TwitterInterface * self;
	self = TWITTER_INTERFACE (obj);
	_g_object_unref0 (self->priv->_friends);
	_g_free0 (self->priv->login);
	_g_free0 (self->priv->password);
	_g_free0 (self->priv->friendsUrl);
	_g_free0 (self->priv->statusUpdateUrl);
	G_OBJECT_CLASS (twitter_interface_parent_class)->finalize (obj);
}


GType twitter_interface_get_type (void) {
	static GType twitter_interface_type_id = 0;
	if (twitter_interface_type_id == 0) {
		static const GTypeInfo g_define_type_info = { sizeof (TwitterInterfaceClass), (GBaseInitFunc) NULL, (GBaseFinalizeFunc) NULL, (GClassInitFunc) twitter_interface_class_init, (GClassFinalizeFunc) NULL, NULL, sizeof (TwitterInterface), 0, (GInstanceInitFunc) twitter_interface_instance_init, NULL };
		twitter_interface_type_id = g_type_register_static (G_TYPE_OBJECT, "TwitterInterface", &g_define_type_info, 0);
	}
	return twitter_interface_type_id;
}


static void twitter_interface_get_property (GObject * object, guint property_id, GValue * value, GParamSpec * pspec) {
	TwitterInterface * self;
	self = TWITTER_INTERFACE (object);
	switch (property_id) {
		case TWITTER_INTERFACE_FRIENDS:
		g_value_set_object (value, twitter_interface_get_friends (self));
		break;
		default:
		G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
		break;
	}
}


static int _vala_strcmp0 (const char * str1, const char * str2) {
	if (str1 == NULL) {
		return -(str1 != str2);
	}
	if (str2 == NULL) {
		return str1 != str2;
	}
	return strcmp (str1, str2);
}




