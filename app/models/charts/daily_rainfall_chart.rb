class DailyRainfallChart < Chart
  include MeteorologicalDay
  
  def data(interval)
    start = meteorological_day_including(interval.begin).begin
    finish = meteorological_day_including(interval.end).end
    sums = instrument.observations.during(start...finish).sum(:value, :group => :meteorological_date)
    zeros = [ 0 ] * sums.length
    series = [ sums.keys.map(&:end_of_day).map(&:to_js), sums.values, sums.values, zeros, zeros ].transpose
    [ series ]
  end

end
