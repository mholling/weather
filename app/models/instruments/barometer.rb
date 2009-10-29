class Barometer < Instrument
  
  validates_size_of :devices, :is => 1
  validate :device_is_ds2438
  
  def read!
    sea_level_pressure_from_voltage(normalised_vad)
  end
  
  %w{altitude minimum_pressure maximum_pressure oversample sensitivity offset gain reference}.each do |attribute|
    define_method "#{attribute}=" do |value|
      self.config[attribute] = value
    end
  
    define_method attribute do
      self.config[attribute]
    end
  end
  
  def setup!
    unless valid?
      puts "Can't set up the barometer yet!"
      puts errors.map { |attribute, error| "#{attribute}: #{error}" }
      return
    end
    
    self.sensitivity ||= 0.0046
    self.offset ||= 0.204

    [ %w{altitude minimum_pressure maximum_pressure oversample}, %w{metres hPa hPa bits}, %w{to_f to_f to_f to_i} ].transpose.map do |attribute, units, convert|
      print "Enter #{attribute.humanize.downcase} in #{units}: "
      self.send "#{attribute}=", gets.send(convert)
    end
    
    calibrate!
  end
  
  def calibrate!
    voltages = sensor_voltage_range
    target_gain = (4.9 - 1.5)/(voltages.max - voltages.min)
    target_reference = (target_gain * voltages.min - 1.5)/(target_gain - 1.0)
    
    calibrate_reference(target_reference)
    calibrate_gain(target_gain)
    
    save
  end
  
  def calibrate_reference(target_reference)
    print "Set jumper to calibration position and press enter to begin reference calibration: "
    gets
    
    self.reference = calibrate_to(target_reference, 0.01)

    puts "Reference voltage calibrated."
  end
  
  def calibrate_gain(target_gain)
    puts "(Reference pressure is %.1f hPa.)" % sea_level_pressure_from_voltage(reference, target_gain)
    print "Enter the current BOM pressure in hPa: "
    pressure = gets.to_f
    
    print "Set jumper to normal position and press enter to begin gain calibration: "
    gets
    
    sensor_voltage = sensor_voltage_from_pressure(convert_from_sea_level(pressure))
    target_voltage = target_gain * (sensor_voltage - reference) + reference
    output_voltage = calibrate_to(target_voltage, 0.01)
    
    self.gain = (output_voltage - reference)/(sensor_voltage - reference)
    
    puts "Gain calibrated. (Calculated gain as %1.4f.)" % gain
  end
  
  def calibrate_to!(web_scraper)
    stats = web_scraper.observations.with_value.with_time(updated_at .. Time.zone.now).map do |scraped_observation|
      nearby_observations = observations.with_time(scraped_observation.time - 5.minutes .. scraped_observation.time + 5.minutes)
      nearest_observation = nearby_observations.inject do |closest_observation, observation|
        (closest_observation.time - scraped_observation.time).abs < (observation.time - scraped_observation.time).abs ? closest_observation : observation
      end
      nearest_observation ? [ nearest_observation.value, scraped_observation.value ] : nil
    end.compact.map do |measured_pressure, scraped_pressure|
      [ sensor_voltage_from_pressure(measured_pressure), scraped_pressure ]
    end.inject(OpenStruct.new(:x => 0.0, :x2 => 0.0, :y => 0.0, :xy => 0.0, :n => 0)) do |sums, (y, x)|
      sums.x  += x
      sums.x2 += x * x
      sums.y  += y
      sums.xy += x * y
      sums.n  += 1
      sums
    end
    
    slope     = (sums.n * sums.xy - sums.x * sums.y )/(sums.n * sums.x2 - sums.x * sums.x)
    intercept = (sums.y * sums.x2 - sums.x * sums.xy)/(sums.n * sums.x2 - sums.x * sums.x)
    
    new_sensitivity = slope / gain
    new_offset = ((gain - 1.0) * reference + intercept + 150.0 * slope)/gain
    
    puts "sensitivity adjustment: %.8f  ->  %.8f" % [ sensitivity, new_sensitivity ]
    puts "offset adjustment:      %.8f  ->  %.8f" % [ offset, new_offsert ]
    puts
    print "y to save: "
    if gets.downcase == "y"
      self.sensitivity, self.offset = new_sensitivity, new_offset
      save
      puts "New sensor calibration saved. (You may wish to recalibrate trimmers.)"
    end
  end
  
  def sensor_voltage_range
    Range.new([ minimum_pressure, maximum_pressure ].map do |pressure|
      convert_from_sea_level(pressure)
    end.map do |pressure|
      sensor_voltage_from_pressure(pressure)
    end)
  end
    
  def sensor_voltage_from_pressure(pressure)
    offset + sensitivity * (pressure - 150)
  end
  
  def pressure_from_sensor_voltage(voltage)
    (voltage - offset)/sensitivity + 150
  end
  
  def sea_level_pressure_from_voltage(voltage, gain = self.gain)
    sensor_voltage = reference + (voltage - reference)/gain
    convert_to_sea_level(pressure_from_sensor_voltage(sensor_voltage))    
  end
  
  def pressure_conversion_factor
    standard_temperature, lapse_rate, gas_constant, molar_mass, gravity = 288.15, -0.0065, 8.31432, 0.0289644, 9.80665
    (standard_temperature/(standard_temperature + lapse_rate * altitude)) ** (gravity * molar_mass/(gas_constant * lapse_rate))
  end
    
  def convert_from_sea_level(pressure)
    pressure * pressure_conversion_factor
  end
  
  def convert_to_sea_level(pressure)
    pressure / pressure_conversion_factor
  end
  
  private
  
  def normalised_vad
    device.oversample(:Vad, oversample) * 5.1 / device.oversample(:Vdd, oversample)
  end
  
  def calibrate_to(target_voltage, error)
    voltages = [ normalised_vad ] * 10
    until voltages.all? { |voltage| (voltage - target_voltage).abs < error }
      sleep 0.5
      voltages.shift
      voltages << normalised_vad
      print "\r%+1.4f" % (voltages.last - target_voltage) # adapt number of decimal places according to error..?
    end
    voltages.last
  end
    
  def device_is_ds2438
    errors.add_to_base("device should be a DS2438") unless device.try(:read, :type) == "DS2438"
  rescue SystemCallError, OneWire::BadRead, OneWire::ShortRead => e
    errors.add_to_base("could not verify the one-wire device (#{e.message.downcase})")
  end
end
