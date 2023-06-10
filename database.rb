require 'sqlite3'
require 'json'
require_relative 'config.rb'

# takes a hash obtained from parsing the cmus status and puts it in the db
# if a track is already in the db it will just increment its play count
def add_to_db(hash)
  db = SQLite3::Database.open $config[:home_path] + "scrobble.db"
  db.execute "insert into artists(name)
              values (\"#{hash[:artist]}\")"
  artist_id = db.execute "select id
                          from artists
                          where name = \"#{hash[:artist]}\""
  db.execute "insert into albums(title, artist)
              values (\"#{hash[:album]}\", \"#{artist_id[0][0]}\")"
  album_id = db.execute "select id
                         from albums
                         where title = \"#{hash[:album]}\" and artist = \"#{artist_id[0][0]}\""
  db.execute "insert into tracks(title, album, artist, duration, plays)
              values (\"#{hash[:title]}\", \"#{album_id[0][0]}\", \"#{artist_id[0][0]}\", \"#{hash[:duration]}\", \"1\")"
  db.close
end
