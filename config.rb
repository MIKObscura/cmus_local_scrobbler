include Errno
$config = {
  :home_path => "",
  :keep_previous_sessions => false,
  :time_to_register => 0.5
}

class String
  def true?
    self == "true"
  end
end

def read_config
  conf = nil
  begin
    conf = File.read("scrobbler_config.txt").split("\n")
  rescue Errno::ENOENT
    return
  end
  conf.each do |c|
    var = c.split("=")[0]
    val = c.split("=")[1]
    if var == "home_path"
      $config[var.to_sym] = val
      next
    end
    if var == "time_to_register"
      $config[var.to_sym] = val.to_f
      next
    end
    $config[var.to_sym] = val.true?
  end
  if $config[:time_to_register] < 0.1
    $config[:time_to_register] = 0.5
  end
end
