require 'ostruct'

class PressureTrend < Statistic
  
  validates_size_of :instruments, :is => 1

  def data(interval)
    return nil unless interval.include?(Time.now.to_meteorological_date)
    pressures = [ 3.hours.ago, Time.zone.now ].map do |time|
      instrument.observations.with_value.with_time(time - 20.minutes .. time)
    end.map do |observations|
      raise ZeroDivisionError if observations.count.zero?
      observations.sum(:value) / observations.count
    end
    pressure_change = pressures.last - pressures.first
    speed = case pressure_change.abs
    when 0.0 ... 3.5 then nil
    when 3.5 ... 6.0 then "rapidly"
    else "very rapidly"
    end
    direction = case
    when pressure_change.abs < 0.3 then "steady"
    when pressure_change > 0.0 then "rising"
    when pressure_change < 0.0 then "falling"
    end
    trend = [ speed, direction ].compact.join(" ")
    pressure = instrument.observations.with_value.with_meteorological_date(interval).last.value
    OpenStruct.new(:pressure => pressure, :trend => trend)
  rescue ZeroDivisionError
    nil
  end
end