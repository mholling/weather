module MeteorologicalDay
  def meteorological_day_including(time)
    start_hour = (APP_CONFIG["start_of_meteorological_day"] || 0)
    date = time.hour >= start_hour ? time.to_date : time.to_date - 1
    start = Time.zone.local(date.year, date.month, date.day, start_hour)
    finish = start + 1.day - 1.second
    start..finish
  end
end