require 'json'
require 'date'
$weekdays = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]

#adds the total time of all the tracks
def get_total_time(tracks)
  time = 0
  tracks.each do | t |
    time += t.total_time
  end
  time
end

#returns all the different artists registered
def get_different_artists(tracks)
  artist_list = []
  tracks.each do | t |
    if artist_list.include? t.artist
      next
    end
    artist_list += [t.artist]
  end
  artist_list.length
end

#returns all the different albums registered
def get_different_albums(tracks)
  album_list = []
  tracks.each do | t |
    if album_list.include? t.album
      next
    end
    album_list += [t.album]
  end
  album_list.length
end

def get_listens(tracks_list, track)
  listens = 0
  tracks_list.each do | t |
    if t.name == track.name
      listens += 1
    end
  end
  listens
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
  artists = {}
  tracks.each do |t|
    if artists.keys.include? t.artist
      artists[t.artist] += t.listens
      next
    end
    artists[t.artist] = t.listens
  end
  artists
end

#same as above but with albums
def get_albums_listen(tracks)
  albums = {}
  tracks.each do |t|
    k = t.artist + " - " + t.album
    if albums.keys.include? k
      albums[k] += t.listens
      next
    end
    albums[k] = t.listens
  end
  albums
end

#same as above but with tracks
def get_tracks_listen(tracks)
  listens = {}
  tracks.each do |t|
    k = t.artist + " - " + t.name
    listens[k] = t.listens
  end
  listens
end

#gets the amount of time in seconds an artist was listened to
def get_artists_listen_time(tracks)
  listen_time = {}
  tracks.each do |t|
    if listen_time.keys.include? t.artist
      listen_time[t.artist] += t.total_time
      next
    end
    listen_time[t.artist] = t.total_time
  end
  listen_time
end

#same but with albums
def get_albums_listen_time(tracks)
  listen_time = {}
  tracks.each do |t|
    k = t.artist + " - " + t.album
    if listen_time.keys.include? k
      listen_time[k] += t.total_time
      next
    end
    listen_time[k] = t.total_time
  end
  listen_time
end

#dumps all of the above functions into a hash
def compute_stats(tracks)
  {
    "listening_time" => get_total_time(tracks),
    "different_tracks" => tracks.length,
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
