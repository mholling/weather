class Minimum < Statistic
  def data(interval)
    instrument.observations.with_value.with_meteorological_date(interval).scoped(:order => "value ASC, time ASC").first
  end
end
