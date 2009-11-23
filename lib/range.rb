class Range
  def utc
    exclude_end? ? self.begin.dup.utc...self.end.dup.utc : self.begin.dup.utc..self.end.dup.utc
  rescue NoMethodError
    raise TypeError, "Must be a Time or DateTime range."
  end
end
