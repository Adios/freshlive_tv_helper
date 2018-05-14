#!/bin/sh -x

if [ $# -lt 2 ]; then
	echo "Usage: $0 CHANNEL_TOKEN PROGRAM_URL"
	exit 64
fi

token=$1
program_url=$2

program_id=`echo $program_url | grep -E -o '[^/]+$'`
appjs_url="https://freshlive.tv`curl $program_url | grep -E -o '/assets/[^/]+/app.js'`"
archive_url="https://movie.freshlive.tv/manifest/$program_id/archive.m3u8?token=$token&version=2&beta4k="

out_uri="$program_id.uri"
out_key="$program_id.key"
out_m3u8="$program_id.m3u8"
out_ts="$program_id.ts"

bin/retrieve_encryption_key_uri.rb "$archive_url" > "$out_uri"
bin/decrypt_key_with_appjs.js `cat "$out_uri"` "$appjs_url" > "$out_key"
bin/customize_playlist.rb "$archive_url" "$out_key" > "$out_m3u8"

ffmpeg -allowed_extensions ALL -protocol_whitelist 'crypto+https,file,crypto,https,tls,tcp' -i "$out_m3u8" -codec copy "$out_ts"
