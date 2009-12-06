class HourlyAverageChart < Chart
  
  validates_size_of :instruments, :is => 1
  
  def data(interval)
    observations = instrument.observations.chronological.with_meteorological_date(interval)
    series = observations.scoped(:select => "AVG(value) AS avg_value, AVG(time) AS avg_time, time", :group => "meteorological_date, HOUR(time)").map do |observation|
      [ observation.time.change(:min => 30).to_js, observation.avg_value ]
    end
    [ series ]
  end

end