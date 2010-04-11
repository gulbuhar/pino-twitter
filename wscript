#!/usr/bin/env python

import intltool

VERSION = "0.2.5"
VERSION_MAJOR_MINOR =  ".".join(VERSION.split(".")[0:2])
APPNAME = "pino"

srcdir = '.'
blddir = '_build_'

def set_options(opt):
	opt.tool_options('compiler_cc')
	opt.tool_options('gnu_dirs')
	opt.add_option('--indicator', action = 'store_true', default = False,
		help = 'Messaging menu support')

def configure(conf):
	conf.check_tool('compiler_cc vala gnu_dirs intltool')
	conf.check_cfg(package='glib-2.0', uselib_store='GLIB',
		atleast_version='2.14.0', mandatory=True, args='--cflags --libs')
	conf.check_cfg(package='gobject-2.0', uselib_store='GOBJECT',
		atleast_version='2.14.0', mandatory=True, args='--cflags --libs')
	conf.check_cfg(package='gtk+-2.0', uselib_store='GTK+',
		atleast_version='2.10.0', mandatory=True, args='--cflags --libs')
	conf.check_cfg(package='gee-1.0', uselib_store='GEE',
		atleast_version='0.5.0', mandatory=True, args='--cflags --libs')
	conf.check_cfg(package='gio-2.0', uselib_store='GIO',
		atleast_version='2.0', mandatory=True, args='--cflags --libs')
	conf.check_cfg(package='libnotify', uselib_store='LIBNOTIFY',
		mandatory=True, args='--cflags --libs')
	#conf.check_cfg(package='libsexy', uselib_store='GTK+',
	#		mandatory=True, args='--cflags --libs')
	conf.check_cfg(package='libsoup-2.4', uselib_store='LIBSOUP',
		atleast_version='2.4', mandatory=True, args='--cflags --libs')
	conf.check_cfg(package='libxml-2.0', uselib_store='LIBXML',
		atleast_version='2.0', mandatory=True, args='--cflags --libs')
	conf.check_cfg(package='webkit-1.0', uselib_store='WEBKIT',
		atleast_version='1.0', mandatory=True, args='--cflags --libs')
	conf.check_cfg(package='unique-1.0', uselib_store='LIBUNIQUE',
		atleast_version='1.0', mandatory=True, args='--cflags --libs')
	conf.check_cfg(package='gtkspell-2.0', uselib_store='GTKSPELL',
		atleast_version='2.0', mandatory=True, args='--cflags --libs')
	conf.check_cfg(package='indicate', uselib_store='LIBINDICATE',
		atleast_version='0.3', mandatory=False, args='--cflags --libs')

	conf.env.append_value('CCFLAGS', '-std=c99')
	
	conf.define('PACKAGE', APPNAME)
	conf.define('PACKAGE_NAME', APPNAME)
	conf.define('PACKAGE_STRING', APPNAME + '-' + VERSION)
	conf.define('PACKAGE_VERSION', APPNAME + '-' + VERSION)

	conf.define('APP_VERSION', VERSION)
	conf.define('DESKTOP_FILE_PATH', conf.env.PREFIX + '/share/applications/pino.desktop')
	conf.define('APP_PATH', conf.env.PREFIX + '/bin/pino')
	conf.define('LOGO_PATH', conf.env.PREFIX + '/share/icons/hicolor/scalable/apps/pino.svg')
	conf.define('LOGO_FRESH_PATH', conf.env.PREFIX + '/share/icons/hicolor/scalable/apps/pino_fresh.svg')
	conf.define('MENTIONS_PATH', conf.env.PREFIX + '/share/pino/icons/mentions.svg')
	conf.define('MENTIONS_FRESH_PATH', conf.env.PREFIX + '/share/pino/icons/mentions_fresh.svg')
	conf.define('TIMELINE_PATH', conf.env.PREFIX + '/share/pino/icons/timeline.svg')
	conf.define('TIMELINE_FRESH_PATH', conf.env.PREFIX + '/share/pino/icons/timeline_fresh.svg')
	conf.define('DIRECT_PATH', conf.env.PREFIX + '/share/pino/icons/direct.svg')
	conf.define('DIRECT_FRESH_PATH', conf.env.PREFIX + '/share/pino/icons/direct_fresh.svg')
	conf.define('PROGRESS_PATH', conf.env.PREFIX + '/share/pino/icons/progress.gif')
	conf.define('DIRECT_REPLY_PATH', conf.env.PREFIX + '/share/pino/icons/direct_reply.png')
	conf.define('FAVORITE_PATH', conf.env.PREFIX + '/share/pino/icons/favorite.png')
	conf.define('FAVORITE_NO_PATH', conf.env.PREFIX + '/share/pino/icons/favorite_no.png')
	#conf.define('FAVORITE_MENU_PATH', conf.env.PREFIX + '/share/pino/icons/favorite_menu.svg')
	conf.define('REPLY_PATH', conf.env.PREFIX + '/share/pino/icons/reply.png')
	conf.define('RETWEET_PATH', conf.env.PREFIX + '/share/pino/icons/re_tweet.png')
	conf.define('DELETE_PATH', conf.env.PREFIX + '/share/pino/icons/delete_status.png')
	conf.define('USERPIC_PATH', conf.env.PREFIX + '/share/pino/icons/userpic.svg')
	conf.define('TEMPLATES_PATH', conf.env.PREFIX + '/share/pino/templates')
	conf.define('VERSION_MAJOR_MINOR', VERSION_MAJOR_MINOR)
	conf.define('LOCALE_DIR', conf.env.PREFIX + '/share/locale/')
	conf.define('GETTEXT_PACKAGE', APPNAME)
	conf.define('APPNAME', APPNAME)

	import Options
	conf.env.INDICATOR = Options.options.indicator
	if(conf.env.INDICATOR):
		conf.define('USE_INDICATOR', 'true')
	
	conf.define('CONS_KEY', 'k6R1A0PPkmpRcThEdPF1Q')
	conf.define('CONS_SEC', 'TKneXwqslxkbaR3RQGcvvvGU4Qk01qh8HAhRIMN74')
	
	# AUTHORS --> About dialog
	f = open('AUTHORS', 'r')
	data = f.read()
	f.close()
	import re
	data = re.sub(r'\n', r'\\n', data)
	conf.define('AUTHORS', data)
	#end
	
	conf.write_config_header("config.h")
	init_defs(conf.env.PREFIX)

def init_defs(prefix):
	"""
	import re
	data = re.sub(r'string PREFIX = \"(.*)\";', 'string PREFIX = "' + prefix + '";', data)
	
	f = open('src/defs.vala', 'w')
	f.write(data)
	f.close()
	"""

def build(bld):
	bld.add_subdirs('src')
	#bld.add_subdirs('liboauth-client')
	bld.add_subdirs('templates')
	bld.add_subdirs('po')
	
	bld.install_files('${PREFIX}/share/icons/hicolor/scalable/apps', 'img/pino.svg')
	bld.install_files('${PREFIX}/share/icons/hicolor/scalable/apps', 'img/pino_fresh.svg')
	bld.install_files('${PREFIX}/share/pino/icons', 'img/mentions.svg')
	bld.install_files('${PREFIX}/share/pino/icons', 'img/mentions_fresh.svg')
	bld.install_files('${PREFIX}/share/pino/icons', 'img/timeline.svg')
	bld.install_files('${PREFIX}/share/pino/icons', 'img/timeline_fresh.svg')
	bld.install_files('${PREFIX}/share/pino/icons', 'img/direct.svg')
	bld.install_files('${PREFIX}/share/pino/icons', 'img/direct_fresh.svg')
	bld.install_files('${PREFIX}/share/pino/icons', 'img/progress.gif')
	bld.install_files('${PREFIX}/share/pino/icons', 'img/direct_reply.png')
	bld.install_files('${PREFIX}/share/pino/icons', 'img/favorite.png')
	bld.install_files('${PREFIX}/share/pino/icons', 'img/favorite_no.png')
	#bld.install_files('${PREFIX}/share/pino/icons', 'img/favorite_menu.svg')
	bld.install_files('${PREFIX}/share/pino/icons', 'img/reply.png')
	bld.install_files('${PREFIX}/share/pino/icons', 'img/re_tweet.png')
	bld.install_files('${PREFIX}/share/pino/icons', 'img/delete_status.png')
	bld.install_files('${PREFIX}/share/pino/icons', 'img/userpic.svg')
	bld.install_files('${PREFIX}/share/applications', 'pino.desktop')
	bld.install_files('${PREFIX}/share/doc/pino', 'COPYING README AUTHORS INSTALL')
	bld.install_files('${PREFIX}/share/indicators/messages/applications', 'indicator/pino')
	
	#import subprocess
	#subprocess.Popen(['desktop-file-install', '--rebuild-mime-info-cache', bld.env.PREFIX + '/share/applications/pino.desktop'], stdout=subprocess.PIPE)

def shutdown(bld):
	"""
	import UnitTest
	unittest = UnitTest.unit_test()
	unittest.want_to_see_test_output = True
	unittest.want_to_see_test_error = True
	unittest.run()
	unittest.print_results()
	"""
