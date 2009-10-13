class Current < Statistic
  def data(interval)
    return nil unless interval.include?(Time.now.to_meteorological_date)
    instrument.observations.with_value.with_meteorological_date(interval).last.value
  end
end