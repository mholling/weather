module JavascriptTime
  def to_js
    (to_i + utc_offset) * 1000
  end
end

[ ActiveSupport::TimeWithZone, Time ].each { |klass| klass.send :include, JavascriptTime }
