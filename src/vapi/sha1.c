/*
 * HMAC-SHA1 implementation via GLib.
 *
 * Copyright (C) 2009 Mark Lee <oauth@lazymalevolence.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *
 * Author : Mark Lee <oauth@lazymalevolence.com>
 */

#include <string.h>
#include "sha1.h"

#define SHA1_BLOCKSIZE 64
#define SHA1_LEN 20

void
_oauth_hmac_sha1 (gchar *key, gchar *message,
                  guchar **output, gsize *output_length)
{
  gssize key_len;
  gchar *final_key;
  gchar opad[SHA1_BLOCKSIZE];
  gchar ipad[SHA1_BLOCKSIZE];
  GChecksum *checksum = g_checksum_new (G_CHECKSUM_SHA1);
  if (strlen (key) > SHA1_BLOCKSIZE)
  {
    guchar new_key[SHA1_LEN];
    key_len = SHA1_LEN;
    g_checksum_update (checksum, key, strlen (key));
    g_checksum_get_digest (checksum, new_key, &key_len);
    g_assert (key_len == SHA1_LEN);
    final_key = g_strdup ((gchar*)new_key);
    g_checksum_reset (checksum);
  }
  else
  {
    final_key = g_strdup (key);
    key_len = strlen (final_key);
  }
  memset (ipad, 0, sizeof (ipad));
  memset (opad, 0, sizeof (opad));
  memcpy (ipad, final_key, key_len);
  memcpy (opad, final_key, key_len);
  g_free (final_key);
  for (gsize i = 0; i < SHA1_BLOCKSIZE; i++)
  {
    ipad[i] ^= 0x36;
    opad[i] ^= 0x5c;
  }
  // inner
  g_checksum_update (checksum, ipad, SHA1_BLOCKSIZE);
  g_checksum_update (checksum, message, strlen (message));
  guchar in[SHA1_LEN];
  gssize in_len = SHA1_LEN;
  g_checksum_get_digest (checksum, in, &in_len);
  g_assert (in_len == SHA1_LEN);
  // outer
  g_checksum_reset (checksum);
  g_checksum_update (checksum, opad, SHA1_BLOCKSIZE);
  g_checksum_update (checksum, in, in_len);
  *output = g_new0 (guchar, SHA1_LEN);
  *output_length = SHA1_LEN;
  g_checksum_get_digest (checksum, *output, output_length);
  g_assert (*output_length == SHA1_LEN);
  g_checksum_free (checksum);
}

/* vim: set et ts=2 sts=2 sw=2 ai cindent : */
