class Current < Statistic
  def value(interval)
    interval.include?(Time.now.to_meteorological_date) ?
      instrument.observations.with_value.with_meteorological_date(interval).last.value :
      nil
  end
end