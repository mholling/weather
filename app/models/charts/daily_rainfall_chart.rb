# class DailyRainfallChart < Chart
#   def series(interval)
#     day = interval.begin
#     data = []
#     while day.start_of_day <= interval.end
#       observations = instrument.observations.chronological.during(day.beginning_of_day...day.end_of_day)
#       data << [ day.start_of_day.to_js, observations.sum(:value) ]
#       day += 1.day
#     end
#     [ data ]
#   end
# end