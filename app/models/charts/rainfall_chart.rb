class RainfallChart < Chart
  def data(interval)
    observations = instrument.observations.chronological.with_value.with_meteorological_date(interval)
    series = [ [ interval.begin.beginning_of_meteorological_day.to_js, 0.0 ] ]
    total = observations.inject(0.0) do |sum, observation|
      series << [ observation.time.to_js, sum ]
      sum += observation.value
      series << [ observation.time.to_js, sum ]
      sum
    end
    series << [ [ interval.end.end_of_meteorological_day, Time.zone.now ].min.to_js, total ]
    [ series ]
  end
end
