class Track
  def initialize(name, artist, album, duration, listens = 1)
    @name = name
    @artist = artist
    @album = album
    @duration = duration.to_i
    @listens = listens.to_i
    @total_time = duration.to_i * listens.to_i
  end

  def name
    @name
  end

  def artist
    @artist
  end

  def album
    @album
  end

  def duration
    @duration
  end

  def listens
    @listens
  end

  def new_listens(new_listen)
    @listens = new_listen
  end

  def more_time
    @listens += 1
  end

  def total_time
    @total_time
  end

  def ==(other)
    @name == other.name and @album == other.album and @duration == other.album
  end
end
