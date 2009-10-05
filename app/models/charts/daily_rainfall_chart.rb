class DailyRainfallChart < Chart
  include MeteorologicalDay
  
  def data(interval)
    start = meteorological_day_including(interval.begin).begin
    finish = meteorological_day_including(interval.end).end
    sums = instrument.observations.during(start..finish).sum(:value, :group => :meteorological_date)
    series = [ sums.keys.map(&:beginning_of_day).map(&:to_js), sums.values ].transpose
    [ series ]
  end

end
