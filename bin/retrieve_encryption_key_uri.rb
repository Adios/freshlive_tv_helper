#!/usr/bin/env ruby

require 'net/http'

require 'bundler/setup'
require 'm3u8'

if ARGV.empty?
  puts "Usage: #{$0} ARCHIVE_URL_WITH_TOKEN"
  exit 64
end

uri = URI(ARGV.shift)

Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
  req = Net::HTTP::Get.new(uri.request_uri)
  data = http.request(req).body

  # further load the playlist with higest bitrate
  best = M3u8::Playlist.read(data).items.max {|a, b| a.bandwidth <=> b.bandwidth }

  req = Net::HTTP::Get.new(best.uri)
  data = http.request(req).body

  M3u8::Playlist.read(data).items.each do |item|
    case item
    when M3u8::KeyItem
      puts item.uri
      exit
    else
      puts 'Find no keys here.'
    end
  end
end

# vim:sts=2 sw=2 expandtab:
