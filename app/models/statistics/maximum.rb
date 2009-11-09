class Maximum < Statistic
  
  validates_size_of :instruments, :is => 1

  def data(interval)
    instrument.observations.with_value.with_meteorological_date(interval).scoped(:order => "value DESC, time ASC").first
  end
end
