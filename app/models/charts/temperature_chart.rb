class TemperatureChart < Chart
  def data(interval)
    series = instrument.observations.chronological.during(interval).map do |observation|
      [ observation.created_at.to_js, observation.value ]
    end
    [ series ]
  end
end