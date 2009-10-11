class Minimum < Statistic
  def value(interval)
    instrument.observations.with_value.with_meteorological_date(interval).minimum(:value)
  end
end
