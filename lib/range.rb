class Range
  def utc
    exclude_end? ? self.begin.utc..self.end.utc : self.begin.utc...self.end.utc
  rescue NoMethodError
    raise TypeError, "Must be a Time or DateTime range."
  end
end