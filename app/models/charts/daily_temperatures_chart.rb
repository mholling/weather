class DailyTemperaturesChart < Chart
  include MeteorologicalDay
  
  def data(interval)
    start = meteorological_day_including(interval.begin).begin
    finish = meteorological_day_including(interval.end).end
    maximums = instrument.observations.during(start...finish).maximum(:value, :group => :meteorological_date)
    minimums = instrument.observations.during(start...finish).minimum(:value, :group => :meteorological_date)
    series = [ maximums.keys.map(&:end_of_day).map(&:to_js), maximums.values, maximums.values, minimums.values, minimums.values ].transpose
    [ series ]
  end

end
