class Minimum < Statistic
  include MeteorologicalDay
  
  def value(interval)
    start = meteorological_day_including(interval.begin).begin
    finish = meteorological_day_including(interval.end).end
    instrument.observations.with_value.during(start..finish).minimum(:value)
  end
end
