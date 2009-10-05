class DailyTemperaturesChart < Chart
  include MeteorologicalDay
  
  def data(interval)
    start = meteorological_day_including(interval.begin).begin
    finish = meteorological_day_including(interval.end).end
    maximums = instrument.observations.with_value.during(start..finish).maximum(:value, :group => :meteorological_date)
    minimums = instrument.observations.with_value.during(start..finish).minimum(:value, :group => :meteorological_date)
    # TODO: need to use non_nil filter once we let in nil values for observations! (in daily rainfall also!)
    maximum_series = [ maximums.keys.map(&:beginning_of_day).map(&:to_js), maximums.values ].transpose
    minimum_series = [ minimums.keys.map(&:beginning_of_day).map(&:to_js), minimums.values ].transpose
    [ maximum_series, minimum_series ]
  end

end
