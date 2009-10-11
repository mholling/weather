class TemperatureChart < Chart
  def data(interval)
    series = instrument.observations.chronological.with_meteorological_date(interval).map do |observation|
      [ observation.time.to_js, observation.value ]
    end
    [ series ]
  end
end
