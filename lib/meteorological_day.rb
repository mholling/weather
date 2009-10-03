module MeteorologicalDay
  def meteorological_day_starting_hour
    APP_CONFIG["start_of_meteorological_day"] || 0
  end
  
  def meteorological_date_for(time)
    time.hour >= meteorological_day_starting_hour ? time.to_date : time.to_date - 1
  end
  
  def meteorological_starting_time_for(date)
    Time.zone.local(date.year, date.month, date.day, meteorological_day_starting_hour)
  end
  
  def meteorological_day_including(time)
    start = meteorological_starting_time_for(meteorological_date_for(time))
    finish = start + 1.day - 1.second
    start..finish
  end
end