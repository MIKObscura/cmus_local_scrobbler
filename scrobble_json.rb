require_relative 'track.rb'
require_relative 'scrobble_stats.rb'
require 'json'
include Errno

#removes the dates from the original json
def unpack_json(json)
  jsons = []
  json.each do | k |
    key = k.keys[0]
    jsons += [k[key]]
  end
  jsons
end

#extracts the hours from the dates
def get_dates_hours(json)
  hours = []
  json.each do | k |
    key = k.keys[0].split(" ")
    hours += [key[1]]
  end
  hours
end

def get_dates(json)
  dates = []
  json.each do | k |
    dates += [k.keys[0]]
  end
  dates
end

#generates all the Track objects from cache
def init_tracks_from_cache
  json_cache = JSON.parse(File.read($config[:home_path] + "cache.json"))
  tracks = []
  json_cache.each do | j |
    new_track = Track.new(j["title"], j["artist"], j["album"], j["duration"], j["listens"])
    tracks += [new_track]
    unless tracks.include? new_track
      next
    end
  end
  tracks
end

#uses the previous function if there is a cache, if not uses given json
def init_tracks(json, cache = false)
  if cache
    tracks = init_tracks_from_cache
    return tracks
  end
  tracks = []
  json.each do | j |
    new_track = Track.new(j["title"], j["albumartist"], j["album"], j["duration"])
    if tracks.any? { | t | t.name == new_track.name and t.artist == new_track.artist }
      index = tracks.find_index { | t | t.name == new_track.name and t.artist == new_track.artist }
      tracks[index].listens += 1
      next
    end
    tracks += [new_track]
  end
  create_cache tracks
  tracks
end

#clears the current session's json
def clear_data(json_data)
  clear = "[]"
  File.write(json_data, clear)
end

#generates cache.json file
def create_cache(tracks)
  cache_file = File.open("cache.json", "w")
  json_str = []
  tracks.each do | t |
    track = {}
    track[:title] = t.name
    track[:artist] = t.artist
    track[:album] = t.album
    track[:duration] = t.duration
    track[:listens] = t.listens
    json_str += [track]
  end
  cache_file.write(JSON.pretty_generate(json_str))
  cache_file.close
end

#returns a hash made from cache.json
def get_cache
  JSON.parse(File.read($config[:home_path] + "cache.json"))
end

#finds the index of an element in the json, returns nil if not found
def json_find(json, el)
  json.find_index { | e | e["artist"] == el["albumartist"] and e["title"] == el["title"] }
end

#adds a track to the cache
def add_to_cache(json_cache, elems)
  cache = get_cache
  elems.each do | e |
    index = json_find(cache, e)
    if !index.nil? #the index exists so we just increment the listens counter
      cache[index]["listens"] += 1
    else #if not we add it
      e["artist"] = e["albumartist"]
      e.delete("albumartist")
      cache << e
      cache[cache.length - 1]["listens"] = 1
    end
  end
  File.write(json_cache, JSON.pretty_generate(cache))
end

def main_stats
  json_file = File.read($json_filename)
  File.truncate($config[:home_path] + "dates.txt", 0)
  dates_file = File.open($config[:home_path] + "dates.txt", "a")
  dates = get_dates(JSON.parse(json_file))
  dates_file.write(dates.join("\n"))
  dates_file.write("\n")
  dates_file.close
  parsed_json = unpack_json(JSON.parse(json_file, {:symbolize_names=>true}))
  parsed_json.each do |t|
    if t[:artist].nil?
      t[:artist] = t[:albumartist]
      t.delete(:albumartist)
    end
    add_to_db t
  end
  db = SQLite3::Database.open $config[:home_path] + "scrobble.db"
  write_stats db
  db.close
end