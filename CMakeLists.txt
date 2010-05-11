# Copyright (C) 2010 Cristian Greco <cristian@regolo.cc>
# Distributed under the same license terms of the program itself (see COPYING).

cmake_minimum_required(VERSION 2.6)

project("pino" C)

set(VERSION "0.2.8")

set(APPNAME "pino")
set(PACKAGE "${APPNAME}")
set(PACKAGE_NAME "${APPNAME}")
set(PACKAGE_STRING "${APPNAME}-${VERSION}")
set(PACKAGE_VERSION "${APPNAME}-${VERSION}")
set(APP_VERSION "${VERSION}")
set(GETTEXT_PACKAGE "${APPNAME}")
string(REGEX REPLACE "([0-9])\\.([0-9]).*" "\\1.\\2" VERSION_MAJOR_MINOR ${VERSION})
file(READ AUTHORS _AUTHORS)
string(REPLACE "\n" "\\n" AUTHORS ${_AUTHORS})

configure_file(config.h.in config.h)
add_definitions(-include config.h)


list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
include(ValaVersion)
include(ValaPrecompile)
find_package(Vala REQUIRED)
ensure_vala_version("0.7" MINIMUM)


option(ENABLE_DEBUG "Enable debug messages" OFF)
option(UBUNTU_ICONS "Install icons for Ubuntu mono themes" OFF)
set(pino_VALA_OPTIONS)


find_package(PkgConfig)
pkg_check_modules(GLIB REQUIRED "glib-2.0 >= 2.14.0")
pkg_check_modules(GOBJECT REQUIRED "gobject-2.0 >= 2.14.0")
pkg_check_modules(GTK+ REQUIRED "gtk+-2.0 >= 2.10.0")
pkg_check_modules(GEE REQUIRED "gee-1.0 >= 0.5.0")
pkg_check_modules(GIO REQUIRED "gio-2.0 >= 2.0")
pkg_check_modules(LIBNOTIFY REQUIRED "libnotify")
pkg_check_modules(LIBSOUP REQUIRED "libsoup-2.4 >= 2.4")
pkg_check_modules(LIBXML REQUIRED "libxml-2.0 >= 2.0")
pkg_check_modules(WEBKIT REQUIRED "webkit-1.0 >= 1.0")
pkg_check_modules(LIBUNIQUE REQUIRED "unique-1.0 >= 1.0")
pkg_check_modules(GTKSPELL REQUIRED "gtkspell-2.0 >= 2.0")
pkg_check_modules(LIBINDICATE "indicate >= 0.3")

if(${LIBINDICATE_FOUND})
  message(STATUS "libindicate found, support enabled...")
  set(pino_VALA_OPTIONS ${pino_VALA_OPTIONS} -D LIBINDICATE)
else()
  message(STATUS "libindicate not found, support disabled...")
endif()


if(ENABLE_DEBUG)
  set(pino_VALA_OPTIONS ${pino_VALA_OPTIONS} -D HAS_DEBUG)
endif()
if(UBUNTU_ICONS)
  set(pino_VALA_OPTIONS ${pino_VALA_OPTIONS} -D HAS_UBUNTUICONS)
endif()


set(pino_VALA_SOURCES
  #src/account_action.vala
  src/accounts.vala
  src/account_widget.vala
  src/cache.vala
  src/color_utils.vala
  src/dm_entry.vala
  src/edit_account.vala
  src/favorites_view_dialog.vala
  src/favorites_view_list.vala
  src/gtk_style.vala
  src/hig_table.vala
  src/log_window.vala
  src/main.vala
  src/main_window.vala
  src/more_window.vala
  #src/oauth-client.vala
  src/popups.vala
  src/pref_dialog.vala
  src/prefs.vala
  src/rest_api_abstract.vala
  src/rest_api_acc.vala
  src/rest_api_direct.vala
  src/rest_api_re.vala
  src/rest_api_timeline.vala
  src/rest_api_user_info.vala
  src/rest_urls.vala
  src/re_tweet.vala
  src/status_bar_smart.vala
  src/status_view_dialog.vala
  src/status_view_list.vala
  src/template.vala
  src/timeline_direct_list.vala
  src/timeline_list_abstract.vala
  src/timeline_list.vala
  src/timer.vala
  src/time_utils.vala
  src/tray_icon.vala
  src/url_short.vala
  src/user_info_list.vala
  src/userpic.vala
  src/account_action.vala
)


vala_precompile(
pino_C_SOURCES
  ${pino_VALA_SOURCES}
PACKAGES
  glib-2.0
  gobject-2.0
  gtk+-2.0
  gee-1.0
  gio-2.0
  libnotify
  libsoup-2.4
  libxml-2.0
  webkit-1.0
  unique-1.0
OPTIONS
  ${pino_VALA_OPTIONS}
CUSTOM_VAPIS
  ${CMAKE_CURRENT_SOURCE_DIR}/src/vapi/config.vapi
)


add_definitions(
  ${GLIB_CFLAGS}
  ${GOBJECT_CFLAGS}
  ${GTK+_CFLAGS}
  ${GEE_CFLAGS}
  ${GIO_CFLAGS}
  ${LIBNOTIFY_CFLAGS}
  ${LIBSOUP_CFLAGS}
  ${LIBXML_CFLAGS}
  ${WEBKIT_CFLAGS}
  ${LIBUNIQUE_CFLAGS}
  ${GTKSPELL_CFLAGS}
  ${LIBINDICATE_CFLAGS}
)

link_libraries(
  ${GLIB_LIBRARIES}
  ${GOBJECT_LIBRARIES}
  ${GTK+_LIBRARIES}
  ${GEE_LIBRARIES}
  ${GIO_LIBRARIES}
  ${LIBNOTIFY_LIBRARIES}
  ${LIBSOUP_LIBRARIES}
  ${LIBXML_LIBRARIES}
  ${WEBKIT_LIBRARIES}
  ${LIBUNIQUE_LIBRARIES}
  ${GTKSPELL_LIBRARIES}
  ${LIBINDICATE_LIBRARIES}
)

include_directories(src/vapi/)
add_definitions(-std=c99)

add_executable(pino
  ${pino_C_SOURCES}
  #src/vapi/sha1.c
  src/vapi/time_parser.c
)

install(TARGETS pino DESTINATION bin)


find_program(MSGFMT_EXECUTABLE msgfmt)
file(GLOB PO_FILES "po/*.po")
set(MO_FILES)
foreach(PO_FILE ${PO_FILES})
  get_filename_component(PO_FILE_BASE ${PO_FILE} NAME_WE)
  set(MO_FILE_PATH ${CMAKE_CURRENT_BINARY_DIR}/po)
  set(MO_FILE ${MO_FILE_PATH}/${PO_FILE_BASE}.mo)

  file(MAKE_DIRECTORY "${MO_FILE_PATH}")
  add_custom_command(
    OUTPUT ${MO_FILE}
    COMMAND ${MSGFMT_EXECUTABLE} -o ${MO_FILE} ${PO_FILE})

  install(FILES ${MO_FILE}
    DESTINATION share/locale/${PO_FILE_BASE}/LC_MESSAGES
    RENAME ${GETTEXT_PACKAGE}.mo)
  set(MO_FILES ${MO_FILES} ${MO_FILE})
endforeach()
add_custom_target(locales ALL DEPENDS ${MO_FILES})


set(pino_IMAGES
  img/delete_status.png
  img/direct_fresh.svg
  img/direct_reply.png
  img/direct.svg
  img/favorite_no.png
  img/favorite.png
  img/mentions_fresh.svg
  img/mentions.svg
  img/progress.gif
  img/reply.png
  img/re_tweet.png
  img/timeline_fresh.svg
  img/timeline.svg
  img/userpic.svg
)
install(FILES ${pino_IMAGES} DESTINATION share/pino/icons)


set(pino_ICONS
  img/pino_fresh.svg
  img/pino.svg
)
install(FILES ${pino_ICONS} DESTINATION share/icons/hicolor/scalable/apps)


set(pino_UBUNTU_ICONS_DARK
 img/ubuntu-mono-dark/pino-tray-icon.svg
 img/ubuntu-mono-dark/pino-tray-icon-fresh.svg
)
set(pino_UBUNTU_ICONS_LIGHT
  img/ubuntu-mono-light/pino-tray-icon.svg
  img/ubuntu-mono-light/pino-tray-icon-fresh.svg
)
if(UBUNTU_ICONS)
  install(FILES ${pino_UBUNTU_ICONS_DARK} DESTINATION share/icons/ubuntu-mono-dark/apps/22)
  install(FILES ${pino_UBUNTU_ICONS_LIGHT} DESTINATION share/icons/ubuntu-mono-light/apps/22)
endif()


set(pino_DOCS
  COPYING
  README
  AUTHORS
  INSTALL
)
install(FILES ${pino_DOCS} DESTINATION share/doc/pino)


set(pino_TEMPLATES
  templates/main.tpl
  templates/status.tpl
  templates/status_direct.tpl
  templates/status_me.tpl
)
install(FILES ${pino_TEMPLATES} DESTINATION share/pino/templates)


install(FILES pino.desktop DESTINATION share/applications)
install(FILES indicator/pino DESTINATION share/indicators/messages/applications)
