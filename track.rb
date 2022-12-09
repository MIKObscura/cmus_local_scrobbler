class Track
  def initialize(name, artist, album, duration, listens = 1)
    @name = name
    @artist = artist
    @album = album
    @duration = duration.to_i
    @listens = listens.to_i
    @total_time = duration.to_i * listens.to_i
  end

  attr_reader :name

  attr_reader :artist

  attr_reader :album

  attr_reader :duration

  attr_reader :total_time

  attr_accessor :listens

  def ==(other)
    @name == other.name and @album == other.album and @duration == other.album
  end
end
