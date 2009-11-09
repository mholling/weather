class SunriseSunsetChart < Chart
  
  validates_size_of :instruments, :is => 0
  
  # def data(interval)
  #   (interval.begin.to_date..interval.end.to_date).map do |date|
  #     location = date.location(config["latitude"], config["longitude"])
  #     [ date, [ location.dawn, location.sunrise, location.sunset, location.dusk ] ]
  #   end.map do |date, times|
  #     [ date, times.map { |time| ((time.hour * 60 + time.min) * 60 + time.sec).to_f / (60 * 60) } ]
  #   end.map do |date, hours|
  #     [ [ date.beginning_of_day.to_js ] * 3, hours[0..2], hours[1..3] ].transpose
  #   end.transpose
  # end

  def data(interval)
    (interval.begin.to_date..interval.end.to_date).map do |date|
      location = date.location(APP_CONFIG["latitude"], APP_CONFIG["longitude"])
      [ [ date, date.beginning_of_day, location.dawn ],
        [ date, location.dawn, location.sunrise ],
        [ date, location.sunset, location.dusk ],
        [ date, location.dusk, date.end_of_day ] ]
    end.map do |bars|
      bars.map do |date, *times|
        [ date.beginning_of_day.to_js, *times.map { |time| ((time.hour * 60 + time.min) * 60 + time.sec).to_f / (60 * 60) } ]
      end
    end.transpose
  end
end