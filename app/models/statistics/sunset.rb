class Sunset < Statistic
  
  validates_size_of :instruments, :is => 0
  
  def data(interval)
    interval.end.to_date.location(APP_CONFIG["latitude"], APP_CONFIG["longitude"]).sunset
  end
end