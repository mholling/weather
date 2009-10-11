class DailyTemperaturesChart < Chart
  def data(interval)
    maximums = instrument.observations.with_value.with_meteorological_date(interval).maximum(:value, :group => :meteorological_date)
    minimums = instrument.observations.with_value.with_meteorological_date(interval).minimum(:value, :group => :meteorological_date)
    series = [ maximums.keys.map(&:beginning_of_day).map(&:to_js), maximums.values, minimums.values ].transpose
    [ series ]
  end
end
