class ActiveSupport::TimeWithZone
  def to_js
    to_i * 1000
  end
  
  def self.now
    new(Time.zone.now.utc, Time.zone)
  end
end

class Time
  def to_js
    to_i * 1000
  end
end
