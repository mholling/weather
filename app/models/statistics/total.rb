class Total < Statistic
  def value(interval)
    instrument.observations.with_value.with_meteorological_date(interval).sum(:value)
  end
end
