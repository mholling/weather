module SunriseSunset
  class DateLocation
    include Math
    DEGREE = 180.0 / PI
    JD_2000 = Date.new(2000).jd.to_f

    def initialize(time_or_date, latitude, longitude)
      date, latitude, longitude = time_or_date.to_date, latitude.to_f, longitude.to_f
      julian_cycle = (date.jd.to_f - JD_2000 - 0.0009 + longitude / 360.0).round
      approximate_solar_noon = JD_2000 + 0.0009 - longitude / 360.0 + julian_cycle
      solar_mean_anomoly = (357.5291 + 0.98560028 * (approximate_solar_noon - JD_2000)) % 360.0
      equation_of_center = 1.9148 * sin(solar_mean_anomoly / DEGREE) + 0.02 * sin(2 * solar_mean_anomoly / DEGREE) + 0.0003 * sin(3 * solar_mean_anomoly / DEGREE)
      ecliptic_longitude = (solar_mean_anomoly + 102.9372 + equation_of_center + 180.0) % 360.0
      solar_transit = approximate_solar_noon + 0.0053 * sin(solar_mean_anomoly / DEGREE) - 0.0069 * sin(2 * ecliptic_longitude / DEGREE)
      declination_of_sun = DEGREE * asin(sin(ecliptic_longitude / DEGREE) * sin(23.45 / DEGREE))
      cos_day_hour_angle = (sin(-0.83 / DEGREE) - sin(latitude / DEGREE) * sin(declination_of_sun / DEGREE))/(cos(latitude / DEGREE) * cos(declination_of_sun / DEGREE))
      cos_twilight_hour_angle = cos_day_hour_angle - tan(6.0 / DEGREE) / cos(latitude / DEGREE)
      @julian_sunset, @julian_sunrise, @julian_dusk, @julian_dawn = nil, nil, nil, nil
      begin
        day_hour_angle = DEGREE * acos(cos_day_hour_angle)
        @julian_sunset = JD_2000 + 0.0009 + (day_hour_angle - longitude) / 360.0 + julian_cycle + 0.0053 * sin(solar_mean_anomoly / DEGREE) - 0.0069 * sin(2 * ecliptic_longitude / DEGREE)
        @julian_sunrise = 2 * solar_transit - @julian_sunset
        twilight_hour_angle = DEGREE * acos(cos_twilight_hour_angle) - day_hour_angle
        @julian_dusk = @julian_sunset + twilight_hour_angle / 360.0
        @julian_dawn = @julian_sunrise - twilight_hour_angle / 360.0
      rescue Errno::EDOM
      end
    end

    %w{dawn sunrise sunset dusk}.each do |method|
      class_eval %{
        def #{method}
          DateTime.jd(@julian_#{method} + 0.5).in_time_zone rescue nil
        end
      }
    end
  end

  def location(latitude, longitude)
    DateLocation.new(self, latitude, longitude)
  end
end

[ ActiveSupport::TimeWithZone, Time, Date ].each { |klass| klass.send :include, SunriseSunset }
