class Maximum < Statistic
  def value(interval)
    instrument.observations.with_value.with_meteorological_date(interval).maximum(:value)
  end
end
