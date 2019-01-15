#!/usr/bin/env ruby

require 'net/http'

require 'bundler/setup'
require 'm3u8'

if ARGV.length < 2
  puts "Usage: #{$0} ARCHIVE_URL_WITH_TOKEN PATH_TO_KEY_FILE"
  exit 64
end

uri = URI(ARGV.shift)
path = File.absolute_path(ARGV.shift)

Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
  req = Net::HTTP::Get.new(uri.request_uri)
  data = http.request(req).body

  # further load the playlist with higest bitrate
  best = M3u8::Playlist.read(data).items.max {|a, b| a.bandwidth <=> b.bandwidth }

  req = Net::HTTP::Get.new(best.uri)
  data = http.request(req).body

  customized = M3u8::Playlist.read(data)
  customized.items.each do |item|
    case item
    when M3u8::KeyItem
      item.uri = path
    when M3u8::SegmentItem
      item.segment = 'https://' + uri.hostname + item.segment
    end
  end

  puts customized
end

# vim:sts=2 sw=2 expandtab:
