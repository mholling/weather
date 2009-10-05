class RainfallChart < Chart
  def data(interval)
    observations = instrument.observations.chronological.during(interval)
    finish = [ interval.end, Time.zone.now ].min
    series = if observations.any?
      observations.inject([ 0.0, [ [ interval.begin.to_js, 0.0 ] ] ]) do |(sum, points), observation|
        points << [ observation.time.to_js, sum ]
        sum += observation.value
        points << [ observation.time.to_js, sum ]
        [ sum, points ]
      end.last << [ finish.to_js, observations.sum(:value) ]
    else
      [ [ interval.begin.to_js, 0.0 ], [ finish.to_js, 0.0 ] ]
    end
    [ series ]
  end

end
