class TimeSeriesChart < Chart
  
  validates_size_of :instruments, :is => 1
  
  def data(interval)
    series = instrument.observations.chronological.with_meteorological_date(interval).map do |observation|
      [ observation.time.to_js, observation.value ]
    end
    [ series ]
  end
end
