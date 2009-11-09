class Total < Statistic
  
  validates_size_of :instruments, :is => 1

  def data(interval)
    instrument.observations.with_value.with_meteorological_date(interval).sum(:value)
  end
end
