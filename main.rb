require 'json'
require 'time'
require_relative 'scrobble_json.rb'
include Errno

def get_cmus_status
  status = `cmus-remote -C status`
  status_lines = []
  if status == "cmus-remote: read: Connection reset by peer"
    return status
  end
  status.each_line do |line|
    status_lines += [line]
  end
  status_lines
end

def parse_cmus_status(status)
  today = Time.now.strftime("%Y-%m-%d %H:%M:%S")
  result_hash = {
    today => {
    "albumartist" => "",
    "album" => "",
    "title" => "",
    "duration" => 0,
    "position" => 0
    }
  }
  keys = result_hash[today].keys
  status.each do |s|
    s_elems = s.split(" ")
    if keys.include? s_elems[1]
      result_hash[today][s_elems[1]] = s_elems[2..s_elems.length].join(" ")
    end
    if s_elems[0] == "duration"
      result_hash[today]["duration"] = s_elems[1].to_i
    end
    if s_elems[0] == "position"
      result_hash[today]["position"] = s_elems[1].to_i
    end
  end
  result_hash
end

def write_to_json(json)
  begin
    file = File.read($home_path + "scrobble_data.json")
  rescue Errno::ENOENT
    file = File.open($home_path + "scrobble_data.json", "w+").read
  end
  json_array = JSON.parse(file)
  json_array << json
  File.write($home_path + "scrobble_data.json", JSON.pretty_generate(json_array))
end

def main
  clear_data($home_path + "scrobble_data.json")
  processes = `ps -a`
  previous_song = nil
  while processes.include? "cmus"
    status = get_cmus_status
    if status == "cmus-remote: read: Connection reset by peer"
      break
    end
    json_status = parse_cmus_status status
    if json_status[json_status.keys[0]]["album"].nil?
      next
    end
    if previous_song.nil?
      json_check = true
    else
      json_check = !(json_status[json_status.keys[0]]["artist"] == previous_song[previous_song.keys[0]]["artist"] and json_status[json_status.keys[0]]["title"] == previous_song[previous_song.keys[0]]["title"])
    end
    if json_check and json_status[json_status.keys[0]]["position"] > (json_status[json_status.keys[0]]["duration"] / 2)
      previous_song = json_status
      json_status[json_status.keys[0]].delete("position")
      write_to_json json_status
    end
    sleep(10)
    processes = `ps -a`
  end
  main_stats
end

main
