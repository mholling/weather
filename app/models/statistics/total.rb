class Total < Statistic
  def data(interval)
    instrument.observations.with_value.with_meteorological_date(interval).sum(:value)
  end
end
