module JavascriptTime
  def to_js
    (to_i + utc_offset) * 1000
  end
end

class ActiveSupport::TimeWithZone
  include JavascriptTime
end

class Time
  include JavascriptTime
end
