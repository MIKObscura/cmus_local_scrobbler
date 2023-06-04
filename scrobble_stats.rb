require 'json'
require 'date'
require 'sqlite3'
WEEKDAYS = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]

# adds the total play time
def get_total_time(tracks)
  tracks.execute("select sum(plays*duration) 
                  from tracks")[0][0]
end

# returns the amount of artists registered
def get_different_artists(tracks)
  tracks.execute("select count(*) 
                  from artists")[0][0]
end

# returns the amount albums registered
def get_different_albums(tracks)
  tracks.execute("select count(*) 
                  from albums")[0][0]
end

# returns the amount of tracks registered
def get_different_tracks(tracks)
  tracks.execute("select count(*) 
                  from tracks")[0][0]
end

# updates the stats for the amount for plays per hours of the day
def listening_hours(dates, stats)
  parsed_stats = JSON.parse(stats)
  hours = parsed_stats["listening_hours"]
  if dates.nil? or dates.length == 0
    return hours
  end
  dates.split("\n").each do |d|
    if d.nil?
      next
    end
    hour_tmp = d.split(" ")[1]
    if hours.keys.include? hour_tmp.split(":")[0].to_i.to_s #need to turn it into an int so we don't have keys like 05 or 00
      #but also need to turn it back to string afterwards so json doesn't throw a tantrum because the key isn't a string
      hours[hour_tmp.split(":")[0].to_i.to_s] += 1
      next
    end
    hours[hour_tmp.split(":")[0].to_i.to_s] = 1
  end
  if hours.keys.length != 24 #checks if all the hours are in there, if not adds the missing one
    (0..23).each do |h|
      if hours.keys.include? h.to_s
        next
      end
      hours[h.to_s] = 0
    end
  end
  hours.sort{|x, y| x[0].to_i <=> y[0].to_i}.to_h
end

# updates the stats for the amount of plays per week day
def listening_days(dates, stats)
  parsed_stats = JSON.parse(stats)
  days = parsed_stats["listening_days"]
  if dates.nil? or dates.length == 0
    return days
  end
  if days.keys.length != 7 # add the missing days if there are any
    WEEKDAYS.each do |w|
      if days.keys.include? w
        next
      end
      days[w] = 0
    end
  end
  dates.split("\n").each do |d|
    if d.nil?
      next
    end
    day = Date.parse(d).wday
    days[WEEKDAYS[day]] += 1
  end
  days
end

# returns the top 10 most played artists
def get_artists_listen(tracks)
  query = tracks.execute "select artists.name, sum(tracks.plays) as total_plays 
                          from artists join tracks on artists.id = tracks.artist 
                          group by artists.name 
                          order by total_plays desc 
                          limit 10"
  hash = {}
  query.each do |r|
    hash[r[0]] = r[1]
  end
  hash
end

#same as above but with albums
def get_albums_listen(tracks)
  query = tracks.execute "select albums.title, artists.name, sum(tracks.plays) as total_plays 
                          from albums join tracks on albums.id = tracks.album join artists on tracks.artist = artists.id 
                          group by albums.title 
                          order by total_plays desc 
                          limit 10"
  hash = {}
  query.each do |r|
    key = r[1] + " - " + r[0]
    hash[key] = r[2]
  end
  hash
end

#same as above but with tracks
def get_tracks_listen(tracks)
  query = tracks.execute "select tracks.title, artists.name, tracks.plays 
                          from tracks join artists on tracks.artist = artists.id 
                          order by tracks.plays desc 
                          limit 10"
  hash = {}
  query.each do |r|
    key = r[1] + " - " + r[0]
    hash[key] = r[2]
  end
  hash
end

#gets the amount of time in seconds an artist was listened to
def get_artists_listen_time(tracks)
  query = tracks.execute "select artists.name, sum(tracks.plays*tracks.duration) as total_time 
                          from artists join tracks on artists.id = tracks.artist 
                          group by artists.name 
                          order by total_time desc 
                          limit 10"
  hash = {}
  query.each do |r|
    hash[r[0]] = r[1]
  end
  hash
end

#same but with albums
def get_albums_listen_time(tracks)
  query = tracks.execute "select albums.title, artists.name, sum(tracks.plays*tracks.duration) as total_time 
                          from albums join tracks on albums.id = tracks.album join artists on artists.id = tracks.artist 
                          group by albums.title 
                          order by total_time desc 
                          limit 10"
  hash = {}
  query.each do |r|
    key = r[1] + " - " + r[0]
    hash[key] = r[2]
  end
  hash
end

#calculates all the weekly, monthly and yearly stats
def period_stats(raw_data)
  stats = {
    :total_tracks => 0,
    :total_artists => 0,
    :total_albums => 0,
    :total_time => 0,
    :artists => {},
    :albums => {},
    :artists_time => {},
    :albums_time => {},
    :hours => {},
    :days => {}
  }
  24.times do |h|
    stats[:hours][h] = 0
  end
  WEEKDAYS.each do |w|
    stats[:days][w] = 0
  end
  stats[:total_tracks] = raw_data.length
  raw_data.each do |v|
    key = v.keys[0]
    val = v[key]
    # increment the plays counter if the artist/album/track is already there
    # initialize it with 1 if not
    if stats[:artists].keys.include? val[:albumartist]
      stats[:artists][val[:albumartist]] += 1
      stats[:artists_time][val[:albumartist]] += val[:duration]
    else
      stats[:artists][val[:albumartist]] = 1
      stats[:artists_time][val[:albumartist]] = val[:duration]
    end
    album_name = "#{val[:albumartist]} - #{val[:album]}"
    if stats[:albums].keys.include? album_name
      stats[:albums][album_name] += 1
      stats[:albums_time][album_name] += val[:duration]
    else
      stats[:albums][album_name] = 1
      stats[:albums_time][album_name] = val[:duration]
    end
    stats[:total_time] += val[:duration]
    date = Time.parse key.to_s
    stats[:days][WEEKDAYS[date.wday]] += 1
    stats[:hours][date.hour.to_s.to_i] += 1
  end
  stats[:total_albums] = stats[:albums].keys.length
  stats[:total_artists] = stats[:artists].keys.length
  stats
end

# clean up the weekly stats file and compute its stats
def last_week_stats
  if $config[:weekly_stats]
    week_ago = (Date.today - 7).to_time
    weekly_stats = JSON.parse(File.read($config[:home_path] + "scrobble_stats_weekly.json"), {:symbolize_names=>true})
    weekly_stats.delete_if { |x| Time.parse(x.keys[0].to_s) < week_ago } #using Time instead of Date because you can't compare Date for some reasons
    File.write($config[:home_path] + "scrobble_stats_weekly.json", JSON.pretty_generate(weekly_stats))
    period_stats(weekly_stats)
  end
end

# same but with monthly stats
def this_month_stats
  if $config[:monthly_stats]
    today = Date.today
    monthly_stats = JSON.parse(File.read($config[:home_path] + "scrobble_stats_monthly.json"), {:symbolize_names=>true})
    monthly_stats.delete_if { |x| Date.parse(x.keys[0].to_s).month != today.month || Date.parse(x.keys[0].to_s).year != today.year}
    File.write($config[:home_path] + "scrobble_stats_monthly.json", JSON.pretty_generate(monthly_stats))
    period_stats(monthly_stats)
  end
end

# same but with yearly stats
def this_year_stats
  if $config[:yearly_stats]
    today = Date.today
    yearly_stats = JSON.parse(File.read($config[:home_path] + "scrobble_stats_yearly.json"), {:symbolize_names=>true})
    yearly_stats.delete_if { |x| Date.parse(x.keys[0].to_s).year != today.year}
    File.write($config[:home_path] + "scrobble_stats_yearly.json", JSON.pretty_generate(yearly_stats))
    period_stats(yearly_stats)
  end
end

# make the JSON object with all the stats
def compute_stats(tracks)
  {
    "listening_time" => get_total_time(tracks),
    "different_tracks" => get_different_tracks(tracks),
    "tracks_listens" => get_tracks_listen(tracks),
    "different_artists" => get_different_artists(tracks),
    "artists_listens" => get_artists_listen(tracks),
    "artists_time" => get_artists_listen_time(tracks),
    "different_albums" => get_different_albums(tracks),
    "albums_listens" => get_albums_listen(tracks),
    "albums_time" => get_albums_listen_time(tracks),
    "listening_hours" => listening_hours(File.read($config[:home_path] + "dates.txt"), File.read($config[:home_path] + "stats.json")),
    "listening_days" => listening_days(File.read($config[:home_path] + "dates.txt"), File.read($config[:home_path] + "stats.json")),
    "last_week" => last_week_stats,
    "this_month" => this_month_stats,
    "this_year" => this_year_stats
  }
end

# dump the JSON object into the file
def write_stats(tracks)
  stats = compute_stats tracks
  File.write($config[:home_path] + "stats.json", JSON.pretty_generate(stats))
end
