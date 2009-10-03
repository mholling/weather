class DailyTemperaturesChart < Chart
  include MeteorologicalDay
  
  def data(interval)
    time = interval.begin.end_of_day
    series = []
    while time <= interval.end
      observations = instrument.observations.during(meteorological_day_including(time))
      min = observations.minimum(:value)
      max = observations.maximum(:value)
      series << [ time.beginning_of_day.to_js, max, max, min, min ] if min && max
      time = time + 1.day
    end
    [ series ]
  end
end
