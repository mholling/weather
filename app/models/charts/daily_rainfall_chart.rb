class DailyRainfallChart < Chart
  def data(interval)
    sums = instrument.observations.with_value.with_meteorological_date(interval).sum(:value, :group => :meteorological_date)
    series = [ sums.keys.map(&:beginning_of_day).map(&:to_js), sums.values ].transpose
    [ series ]
  end
end
