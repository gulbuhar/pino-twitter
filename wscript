#!/usr/bin/env python

import intltool

VERSION = "0.1.0"
VERSION_MAJOR_MINOR =  ".".join(VERSION.split(".")[0:2])
APPNAME = "pino"

srcdir = '.'
blddir = '_build_'

def set_options(opt):
	opt.tool_options('compiler_cc')
	opt.tool_options('gnu_dirs')

def configure(conf):
	conf.check_tool('compiler_cc vala gnu_dirs intltool')
	conf.check_cfg(package='glib-2.0', uselib_store='GLIB',
			atleast_version='2.14.0', mandatory=True, args='--cflags --libs')
	conf.check_cfg(package='gobject-2.0', uselib_store='GOBJECT',
			atleast_version='2.14.0', mandatory=True, args='--cflags --libs')
	conf.check_cfg(package='gtk+-2.0', uselib_store='GTK+',
			atleast_version='2.10.0', mandatory=True, args='--cflags --libs')
	conf.check_cfg(package='gee-1.0', uselib_store='GEE',
			atleast_version='0.3.0', mandatory=True, args='--cflags --libs')
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

	conf.define('PACKAGE', APPNAME)
	conf.define('PACKAGE_NAME', APPNAME)
	conf.define('PACKAGE_STRING', APPNAME + '-' + VERSION)
	conf.define('PACKAGE_VERSION', APPNAME + '-' + VERSION)

	conf.define('APP_VERSION', VERSION)
	conf.define('LOGO_PATH', conf.env.PREFIX + '/share/icons/hicolor/scalable/apps/pino.svg')
	conf.define('LOGO_FRESH_PATH', conf.env.PREFIX + '/share/icons/hicolor/scalable/apps/pino_fresh.svg')
	conf.define('MENTIONS_PATH', conf.env.PREFIX + '/share/icons/hicolor/scalable/actions/mentions.svg')
	conf.define('TIMELINE_PATH', conf.env.PREFIX + '/share/icons/hicolor/scalable/actions/timeline.svg')
	conf.define('TEMPLATES_PATH', conf.env.PREFIX + '/share/pino/templates')
	conf.define('VERSION_MAJOR_MINOR', VERSION_MAJOR_MINOR)
	conf.define('LOCALE_DIR', conf.env.PREFIX + '/share/locale/')
	conf.define('GETTEXT_PACKAGE', APPNAME)
	conf.define('APPNAME', APPNAME)
	
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
	bld.add_subdirs('templates')
	bld.add_subdirs('po')
	
	bld.install_files('${PREFIX}/share/icons/hicolor/scalable/apps', 'pino.svg')
	bld.install_files('${PREFIX}/share/icons/hicolor/scalable/apps', 'pino_fresh.svg')
	bld.install_files('${PREFIX}/share/icons/hicolor/scalable/actions', 'mentions.svg')
	bld.install_files('${PREFIX}/share/icons/hicolor/scalable/actions', 'timeline.svg')
	#bld.install_files('${PREFIX}/share/icons/hicolor/16x16/actions', 'retweet.png')
	bld.install_files('${PREFIX}/share/applications', 'pino.desktop')
	bld.install_files('${PREFIX}/share/doc/pino', 'COPYING README AUTHORS INSTALL')
	
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
