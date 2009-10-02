module MeteorologicalDay
  def meteorological_day_including(time)
    offset = (APP_CONFIG["start_of_meteorological_day"] || 0).hours
    start = (time - offset).beginning_of_day + offset
    finish = start + 1.day
    start..finish
  end
end