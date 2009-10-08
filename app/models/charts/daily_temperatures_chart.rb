class DailyTemperaturesChart < Chart
  include MeteorologicalDay
  
  def data(interval)
    start = meteorological_day_including(interval.begin).begin
    finish = meteorological_day_including(interval.end).end
    maximums = instrument.observations.with_value.during(start..finish).maximum(:value, :group => :meteorological_date)
    minimums = instrument.observations.with_value.during(start..finish).minimum(:value, :group => :meteorological_date)
    series = [ maximums.keys.map(&:beginning_of_day).map(&:to_js), maximums.values, minimums.values ].transpose
    [ series ]
  end
end
