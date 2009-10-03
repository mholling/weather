class RainfallChart < Chart
  def data(interval)
    observations = instrument.observations.chronological.during(interval)
    series = observations.inject([ 0.0, [ ] ]) do |(sum, points), observation|
      sum += observation.value
      [ sum, points << [ observation.time.to_js, sum ] ]
    end.last
    
    if observations.first
      series.unshift [ [ observations.first.time - instrument.default_interval, interval.begin ].max.to_js, 0.0 ]
    end
    series.unshift [ interval.begin.to_js, 0.0 ]
    series.push    [ [ interval.end, ActiveSupport::TimeWithZone.now ].min.to_js, series.last[1] ]
    [ series ]
  end
end