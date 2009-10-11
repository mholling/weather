class Mean < Statistic
  def value(interval)
    instrument.observations.with_value.with_meteorological_date(interval).average(:value) # TODO: dodgy!!
  end
end