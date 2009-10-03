class ActiveSupport::TimeWithZone
  def to_js
    to_i * 1000
  end
end

class Time
  def to_js
    to_i * 1000
  end
end
