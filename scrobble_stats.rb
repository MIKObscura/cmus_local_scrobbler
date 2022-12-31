require 'json'
require 'date'
require 'sqlite3'
$weekdays = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]

#adds the total time of all the tracks
def get_total_time(tracks)
  tracks.execute("select sum(plays*duration) from tracks")[0][0]
end

#returns all the different artists registered
def get_different_artists(tracks)
  tracks.execute("select count(*) from artists")[0][0]
end

#returns all the different albums registered
def get_different_albums(tracks)
  tracks.execute("select count(*) from albums")[0][0]
end

def get_different_tracks(tracks)
  tracks.execute("select count(*) from tracks")[0][0]
end

def listening_hours(dates, cache)
  parsed_cache = JSON.parse(cache)
  hours = parsed_cache["listening_hours"]
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

def listening_days(dates, cache)
  parsed_cache = JSON.parse(cache)
  days = parsed_cache["listening_days"]
  if dates.nil? or dates.length == 0
    return days
  end
  if days.keys.length != 7
    $weekdays.each do |w|
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
    days[$weekdays[day]] += 1
  end
  days
end

def get_artists_listen(tracks)
  query = tracks.execute "select artists.name, sum(tracks.plays) as total_plays from artists join tracks on artists.id = tracks.artist group by artists.name order by total_plays desc limit 10"
  hash = {}
  query.each do |r|
    hash[r[0]] = r[1]
  end
  hash
end

#same as above but with albums
def get_albums_listen(tracks)
  query = tracks.execute "select albums.title, artists.name, sum(tracks.plays) as total_plays from albums join tracks on albums.id = tracks.album join artists on tracks.artist = artists.name group by albums.title order by total_plays desc limit 10"
  hash = {}
  query.each do |r|
    key = r[1] + " - " + r[0]
    hash[key] = r[2]
  end
  hash
end

#same as above but with tracks
def get_tracks_listen(tracks)
  query = tracks.execute "select tracks.title, artists.name, tracks.plays from tracks join artists on tracks.artist = artists.id order by tracks.plays desc limit 10"
  hash = {}
  query.each do |r|
    key = r[1] + " - " + r[0]
    hash[key] = r[2]
  end
  hash
end

#gets the amount of time in seconds an artist was listened to
def get_artists_listen_time(tracks)
  query = tracks.execute "select artists.name, sum(tracks.plays*tracks.duration) as total_time from artists join tracks on artists.id = tracks.artist group by artists.name order by total_time desc limit 10"
  hash = {}
  query.each do |r|
    hash[r[0]] = r[1]
  end
  hash
end

#same but with albums
def get_albums_listen_time(tracks)
  query = tracks.execute "select albums.title, artists.name, sum(tracks.plays*tracks.duration) as total_time from albums join tracks on albums.id = tracks.album join artists on artists.id = tracks.artist group by albums.title order by total_time desc limit 10"
  hash = {}
  query.each do |r|
    key = r[1] + " - " + r[0]
    hash[key] = r[2]
  end
  hash
end

#dumps all of the above functions into a hash
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
    "listening_days" => listening_days(File.read($config[:home_path] + "dates.txt"), File.read($config[:home_path] + "stats.json"))
  }
end

def write_stats(tracks)
  stats = compute_stats tracks
  File.write($config[:home_path] + "stats.json", JSON.pretty_generate(stats))
end
