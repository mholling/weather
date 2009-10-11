module MeteorologicalDate
  def to_meteorological_date
    hour >= (APP_CONFIG["start_of_meteorological_day"] || 0) ? to_date : to_date - 1
  end
  
  def beginning_of_meteorological_day
    Time.local(year, month, day, APP_CONFIG["start_of_meteorological_day"] || 0)
  end
  
  def end_of_meteorological_day
    Time.local(year, month, day, APP_CONFIG["start_of_meteorological_day"] || 0) + 1.day - 1.second
  end
end

[ ActiveSupport::TimeWithZone, Time, Date ].each { |klass| klass.send :include, MeteorologicalDate }
