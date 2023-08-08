require_relative 'scrobble_stats.rb'
require_relative 'config.rb'
require_relative 'database.rb'
require 'json'
require 'time'
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

#clears the current session's json
def clear_data(json_data)
  clear = "[]"
  File.write(json_data, clear)
end

#finds the index of an element in the json, returns nil if not found
def json_find(json, el)
  json.find_index { | e | e["artist"] == el["artist"] and e["title"] == el["title"] }
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
    if t[:artist].nil? or t[:artist] == "" # artist and albumartist are the same thing, not sure why they both exist
      t[:artist] = t[:albumartist]
      t.delete(:albumartist)
    end
    add_to_db t
  end
  db = SQLite3::Database.open $config[:home_path] + "scrobble.db"
  write_stats db
  db.close
end