require 'sqlite3'
require 'json'
require_relative 'config.rb'

def add_to_db(hash)
  db = SQLite3::Database.open $config[:home_path] + "scrobble.db"
  artist_id = db.execute "select id from artists where name = \"#{hash[:artist]}\""
  if artist_id.empty?
    db.execute "insert into artists(name) values (\"#{hash[:artist]}\")"
    artist_id = db.execute "select id from artists where name = \"#{hash[:artist]}\""
    db.execute "insert into albums(title, artist) values (\"#{hash[:album]}\", \"#{artist_id[0][0]}\")"
    album_id = db.execute "select id from albums where title = \"#{hash[:album]}\" and artist = \"#{artist_id[0][0]}\""
    db.execute "insert into tracks(title, album, artist, duration) values (\"#{hash[:title]}\", \"#{album_id[0][0]}\", \"#{artist_id[0][0]}\", \"#{hash[:duration]}\")"
    return
  end
  album_id = db.execute "select id from albums where title = \"#{hash[:album]}\" and artist = \"#{artist_id[0][0]}\""
  if album_id.empty?
    db.execute "insert into albums(title, artist) values (\"#{hash[:album]}\", \"#{artist_id[0][0]}\")"
  end
  album_id = db.execute "select id from albums where title = \"#{hash[:album]}\" and artist = \"#{artist_id[0][0]}\""
  track = db.execute "select id from tracks where title = \"#{hash[:title]}\" and artist = \"#{artist_id[0][0]}\" and album = \"#{album_id[0][0]}\""
  if track.empty?
    db.execute "insert into tracks(title, album, artist, duration, plays) values (\"#{hash[:title]}\", \"#{album_id[0][0]}\", \"#{artist_id[0][0]}\", \"#{hash[:duration]}\", \"1\")"
  else
    listens = db.execute "select plays from tracks where title = \"#{hash[:title]}\" and artist = \"#{artist_id[0][0]}\" and album = \"#{album_id[0][0]}\""
    db.execute "update tracks set plays=\"#{listens[0][0]+1}\" where title = \"#{hash[:title]}\" and artist = \"#{artist_id[0][0]}\" and album = \"#{album_id[0][0]}\""
  end
  db.close
end
