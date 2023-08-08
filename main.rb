require 'json'
require 'time'
require_relative 'scrobble_json.rb'
require_relative 'config.rb'
include Errno

#returns the cmus status
def get_cmus_status
  status = `cmus-remote -C status`
  status_lines = []
  if status == "cmus-remote: read: Connection reset by peer" #value of the status when cmus is stopped
    return status
  end
  status.each_line do |line| #turn it into an array to make reading it easier
    status_lines += [line]
  end
  if $config[:log_level] == 'debug'
    puts "========= Full status ========"
    puts status_lines
  end
  status_lines
end

#turns the status into a hash
def parse_cmus_status(status)
  today = Time.now.strftime("%Y-%m-%d %H:%M:%S")
  result_hash = {
    today => {
    "artist" => "", #all of the elements that we're interested in
    "albumartist" => "", #in case it doesn't have an artist field but only this one instead
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
  if result_hash[today]["artist"] == "" or result_hash[today]["artist"].nil?
    result_hash[today]["artist"] = result_hash[today]["albumartist"]
    result_hash[today].delete("albumartist")
  end
  if $config[:log_level] == 'debug' or $config[:log_level] == 'info'
    puts "======= Parsed status =========="
    puts result_hash
  end
  result_hash
end

#dumps the hash into the current session's json and to the other stats files if specified
def write_to_json(json)
  begin
    file = File.read($json_filename)
  rescue Errno::ENOENT
    file = File.open($json_filename, "w+").read
  end
  json_array = JSON.parse(file)
  json_array << json
  File.write($json_filename, JSON.pretty_generate(json_array))
  if $config[:weekly_stats]
    begin
      week_file = File.read($config[:home_path] + "scrobble_stats_weekly.json")
    rescue Errno::ENOENT
      week_file = File.open($config[:home_path] + "scrobble_stats_weekly.json", "w+").read
    end
    json_week = JSON.parse(week_file)
    json_week << json
    File.write($config[:home_path] + "scrobble_stats_weekly.json", JSON.pretty_generate(json_week))
  end
  if $config[:monthly_stats]
    begin
      month_file = File.read($config[:home_path] + "scrobble_stats_monthly.json")
    rescue Errno::ENOENT
      month_file = File.open($config[:home_path] + "scrobble_stats_monthly.json", "w+").read
    end
    json_month = JSON.parse(month_file)
    json_month << json
    File.write($config[:home_path] + "scrobble_stats_monthly.json", JSON.pretty_generate(json_month))
  end
  if $config[:yearly_stats]
    begin
      year_file = File.read($config[:home_path] + "scrobble_stats_yearly.json")
    rescue Errno::ENOENT
      year_file = File.open($config[:home_path] + "scrobble_stats_yearly.json", "w+").read
    end
    json_year = JSON.parse(year_file)
    json_year << json
    File.write($config[:home_path] + "scrobble_stats_yearly.json", JSON.pretty_generate(json_year))
  end
end

def main
  read_config
  if $config[:log_level] == "debug"
    puts "======= Configuration ========="
    puts $config
    puts "==============================="
  end
  today = Time.now
  $json_filename = $config[:home_path] + "scrobble_data.json"
  if $config[:keep_previous_sessions]
    $json_filename = $config[:home_path] + "scrobble_data_%d%d%d%d%d.json" % [today.day, today.month, today.year, today.hour, today.min]
  end
  clear_data($json_filename)
  processes = `ps -A`
  previous_song = nil
  while processes.include? "cmus" #automatically ends when cmus isn't running
    status = get_cmus_status
    if status == "cmus-remote: read: Connection reset by peer" #in case it catches the status before cmus stops (doesn't happen most of the time)
      break
    end
    json_status = parse_cmus_status status
    if json_status[json_status.keys[0]]["album"].nil? #avoids adding empty json into the file, there isn't a particular
      # reason why this key was used, it works with any other
      next
    end
    if previous_song.nil? #sets the previous song to compare for the next iteration
      json_check = true
    else
      json_check = !(json_status[json_status.keys[0]]["artist"] == previous_song[previous_song.keys[0]]["artist"] and json_status[json_status.keys[0]]["title"] == previous_song[previous_song.keys[0]]["title"])
    end
    register_time = $config[:time_to_register] < 1 ? (json_status[json_status.keys[0]]["duration"] * $config[:time_to_register].to_f).to_i: $config[:time_to_register].to_i
    if json_check and json_status[json_status.keys[0]]["position"] > register_time
      previous_song = json_status
      json_status[json_status.keys[0]].delete("position")
      write_to_json json_status
    end
    sleep(10) #wait 10s, no point in checking all the time
    processes = `ps -A`
  end
  main_stats
end

main
