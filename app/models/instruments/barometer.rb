class Pressure
  STANDARD_TEMPERATURE, LAPSE_RATE, GAS_CONSTANT, MOLAR_MASS, GRAVITY = 288.15, -0.0065, 8.31432, 0.0289644, 9.80665

  attr_reader :value, :altitude
  
  def initialize(value, altitude)
    self.value, self.altitude = value, altitude
  end
  
  def to_sea_level
    to_altitude(0.0)
  end
  
  def to_altitude(altitude)
    new(value * Pressure.conversion_factor(altitude) / Pressure.conversion_factor(self.altidute), altitude)
  end
  
  delegate :to_f, :to => :value
  
  def self.conversion_factor(altitude)
    altitude.zero? 1.0 : (STANDARD_TEMPERATURE/(STANDARD_TEMPERATURE + LAPSE_RATE * altitude)) ** (GRAVITY * MOLAR_MASS/(GAS_CONSTANT * LAPSE_RATE))
  end
end

class Barometer < Instrument
  
  validates_size_of :devices, :is => 1
  validate :device_is_ds2438
  
  def read!
    pressure_from_output_voltage(normalised_vad).to_sea_level.to_f
  end
  
  %w{altitude oversample sensitivity offset gradient intercept}.each do |attribute|
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

    print "Enter altitude in metres: "
    self.altitude = gets.to_f
    print "Enter minimum pressure in hPa: "
    minimum_pressure = Pressure.new(gets.to_f, 0.0)
    print "Enter maximum pressure in hPa: "
    maximum_pressure = Pressure.new(gets.to_f, 0.0)
    print "Enter oversample in bits: "
    self.oversample = gets.to_i
    
    minimum_sensor_voltage = sensor_voltage_from_pressure(minimum_pressure)
    maximum_sensor_voltage = sensor_voltage_from_pressure(maximum_pressure)
    target_gain = (4.9 - 1.5)/(maximum_sensor_voltage - minimum_sensor_voltage)
    target_reference = (target_gain * minimum_sensor_voltage - 1.5)/(target_gain - 1.0)
    
    reference = calibrate_reference(target_reference)
    gain = calibrate_gain(target_gain, reference)
    
    self.gradient = sensitivity * gain
    self.intercept = 150.0 + (reference * (gain - 1.0) / gain - offset) / sensitivity
    
    save
  end
  
  def calibrate_reference(target_reference)
    print "Set jumper to calibration position and press enter to begin reference calibration: "
    gets
    
    returning calibrate_vad_to(target_reference, 0.01) do |reference|
      puts "Reference voltage calibrated as %1.4f volts." % reference
    end
  end
  
  def calibrate_gain(target_gain, reference)
    print "Enter the current BOM pressure in hPa: "
    current_pressure = Pressure.new(gets.to_f, 0.0)
    
    reference_pressure = pressure_from_sensor_voltage(reference)
    if (current_pressure.to_sea_level.to_f - reference_pressure.to_sea_level.to_f).abs < 5.0
      puts "(Close to reference pressure of %1.4f; results could be poor.)" % reference_pressure
    end
    
    print "Set jumper to normal position and press enter to begin gain calibration: "
    gets
    
    sensor_voltage = sensor_voltage_from_pressure(current_pressure)
    target_voltage = target_gain * (sensor_voltage - reference) + reference
    
    actual_voltage = calibrate_vad_to(target_voltage, 0.01)
    
    returning (actual_voltage - reference)/(sensor_voltage - reference) do |gain|
      puts "Gain calibrated as %1.4f." % gain
    end
  end
  
  def calibrate_vad_to(target_voltage, error)
    voltages = [ normalised_vad ] * 10
    until voltages.all? { |voltage| (voltage - target_voltage).abs < error }
      sleep 0.5
      voltages.shift
      voltages << normalised_vad
      print "\r%+1.4f" % (voltages.last - target_voltage) # adapt number of decimal places according to error..?
    end
    voltages.last
  end

  def sensor_voltage_from_pressure(pressure)
    offset + sensitivity * (pressure.to_altitude(altitude).to_f - 150.0)
  end

  def pressure_from_sensor_voltage(voltage)
    Pressure.new((voltage - offset)/sensitivity + 150.0, altitude).to_sea_level
  end
  
  def output_voltage_from_pressure(pressure)
    (pressure.to_sea_level.to_f - intercept)/gradient
  end
  
  def pressure_from_output_voltage(voltage)
    Pressure.new(intercept + gradient * voltage, 0.0)
  end

  def normalised_vad
    device.oversample(:Vad, oversample) * 5.1 / device.oversample(:Vdd, oversample)
  end

  def calibrate_to!(web_scraper)
    stats = web_scraper.observations.with_value.with_time(updated_at .. Time.zone.now).map do |scraped_observation|
      nearby_observations = observations.with_time(scraped_observation.time - 5.minutes .. scraped_observation.time + 5.minutes)
      nearest_observation = nearby_observations.inject do |closest_observation, observation|
        (closest_observation.time - scraped_observation.time).abs < (observation.time - scraped_observation.time).abs ? closest_observation : observation
      end
      nearest_observation ? [ Pressure.new(nearest_observation.value, 0.0), scraped_observation.value ] : nil
    end.compact.map do |measured_pressure, scraped_pressure_value|
      [ output_voltage_from_pressure(measured_pressure), scraped_pressure_value ]
    end.inject(OpenStruct.new(:v => 0.0, :v2 => 0.0, :p => 0.0, :vp => 0.0, :n => 0)) do |sums, (v, p)|
      sums.v += v; sums.v2 += v * v; sums.p += p; sums.vp += v * p; sums.n += 1
      sums
    end
    
    new_gradient  = (sums.n * sums.vp - sums.v * sums.p )/(sums.n * sums.v2 - sums.v * sums.v)
    new_intercept = (sums.p * sums.v2 - sums.v * sums.vp)/(sums.n * sums.v2 - sums.v * sums.v)
    
    rows = [ ["", " Before ", " After "] ]
    rows << [ " Lowest Pressure ",  " %.1f hPa " % (intercept + gradient * 1.5), " %.1f hPa " % (new_intercept + new_gradient * 1.5) ]
    rows << [ " Highest Pressure ", " %.1f hPa " % (intercept + gradient * 4.9), " %.1f hPa " % (new_intercept + new_gradient * 4.9) ]
    rows << [ " Resolution ", " %.4f hPa " % gradient * 0.01, " %.4f hPa " % new_gradient * 0.01 ]
    widths = rows.transpose.map { |entries| entries.map(&:length).max }
    rows.insert(1, widths.map { |width| "-" * width })
    puts
    puts rows.map { |entries| [ entries, widths ].transpose.map { |entry, width| "%-#{width}s" % entry }.join("|") }
    puts
    
    print "y to save: "
    if gets.downcase == "y"
      self.gradient, self.intercept = new_gradient, new_intercept
      save
      puts "New sensor calibration saved."
      # # TODO: code here to update sensitivity and offset for next recalibration?
      # puts "New sensor calibration saved. (You may wish to recalibrate trimmers.)"
    end
  end
    
  protected
  
  def device_is_ds2438
    errors.add_to_base("device should be a DS2438") unless device.try(:read, :type) == "DS2438"
  rescue SystemCallError, OneWire::BadRead, OneWire::ShortRead => e
    errors.add_to_base("could not verify the one-wire device (#{e.message.downcase})")
  end
end






# class Barometer < Instrument
#   
#   validates_size_of :devices, :is => 1
#   validate :device_is_ds2438
#   
#   def read!
#     sea_level_pressure_from_voltage(normalised_vad)
#   end
#   
#   %w{altitude minimum_pressure maximum_pressure oversample sensitivity offset gain reference}.each do |attribute|
#     define_method "#{attribute}=" do |value|
#       self.config[attribute] = value
#     end
#   
#     define_method attribute do
#       self.config[attribute]
#     end
#   end
#   
#   def setup!
#     unless valid?
#       puts "Can't set up the barometer yet!"
#       puts errors.map { |attribute, error| "#{attribute}: #{error}" }
#       return
#     end
#     
#     self.sensitivity ||= 0.0046
#     self.offset ||= 0.204
# 
#     [ %w{altitude minimum_pressure maximum_pressure oversample}, %w{metres hPa hPa bits}, %w{to_f to_f to_f to_i} ].transpose.map do |attribute, units, convert|
#       print "Enter #{attribute.humanize.downcase} in #{units}: "
#       self.send "#{attribute}=", gets.send(convert)
#     end
#     
#     calibrate!
#   end
#   
#   def calibrate!
#     target_gain = (4.9 - 1.5)/(sensor_voltage_range.max - sensor_voltage_range.min)
#     target_reference = (target_gain * sensor_voltage_range.min - 1.5)/(target_gain - 1.0)
#     
#     calibrate_reference(target_reference)
#     calibrate_gain(target_gain)
#     
#     save
#   end
#   
#   def calibrate_reference(target_reference)
#     print "Set jumper to calibration position and press enter to begin reference calibration: "
#     gets
#     
#     self.reference = calibrate_to(target_reference, 0.01)
# 
#     puts "Reference voltage calibrated."
#   end
#   
#   def calibrate_gain(target_gain)
#     puts "(Reference pressure is %.1f hPa.)" % sea_level_pressure_from_voltage(reference, target_gain)
#     print "Enter the current BOM pressure in hPa: "
#     pressure = gets.to_f
#     
#     print "Set jumper to normal position and press enter to begin gain calibration: "
#     gets
#     
#     sensor_voltage = sensor_voltage_from_pressure(convert_from_sea_level(pressure))
#     target_voltage = target_gain * (sensor_voltage - reference) + reference
#     output_voltage = calibrate_to(target_voltage, 0.01)
#     
#     self.gain = (output_voltage - reference)/(sensor_voltage - reference)
#     
#     puts "Gain calibrated. (Calculated gain as %1.4f.)" % gain
#   end
#   
#   def calibrate_to!(web_scraper)
#     stats = web_scraper.observations.with_value.with_time(updated_at .. Time.zone.now).map do |scraped_observation|
#       nearby_observations = observations.with_time(scraped_observation.time - 5.minutes .. scraped_observation.time + 5.minutes)
#       nearest_observation = nearby_observations.inject do |closest_observation, observation|
#         (closest_observation.time - scraped_observation.time).abs < (observation.time - scraped_observation.time).abs ? closest_observation : observation
#       end
#       nearest_observation ? [ nearest_observation.value, scraped_observation.value ] : nil
#     end.compact.map do |measured_pressure, scraped_pressure|
#       [ sensor_voltage_from_pressure(measured_pressure), scraped_pressure ]
#     end.inject(OpenStruct.new(:x => 0.0, :x2 => 0.0, :y => 0.0, :xy => 0.0, :n => 0)) do |sums, (y, x)|
#       sums.x  += x
#       sums.x2 += x * x
#       sums.y  += y
#       sums.xy += x * y
#       sums.n  += 1
#       sums
#     end
#     
#     slope     = (sums.n * sums.xy - sums.x * sums.y )/(sums.n * sums.x2 - sums.x * sums.x)
#     intercept = (sums.y * sums.x2 - sums.x * sums.xy)/(sums.n * sums.x2 - sums.x * sums.x)
#     
#     new_sensitivity = slope / gain
#     new_offset = ((gain - 1.0) * reference + intercept + 150.0 * slope)/gain
#     
#     puts "sensitivity adjustment: %.8f  ->  %.8f" % [ sensitivity, new_sensitivity ]
#     puts "offset adjustment:      %.8f  ->  %.8f" % [ offset, new_offsert ]
#     puts
#     print "y to save: "
#     if gets.downcase == "y"
#       self.sensitivity, self.offset = new_sensitivity, new_offset
#       save
#       puts "New sensor calibration saved. (You may wish to recalibrate trimmers.)"
#     end
#   end
#   
#   def sensor_voltage_range
#     Range.new([ minimum_pressure, maximum_pressure ].map do |pressure|
#       convert_from_sea_level(pressure)
#     end.map do |pressure|
#       sensor_voltage_from_pressure(pressure)
#     end)
#   end
#     
#   def sensor_voltage_from_pressure(pressure)
#     offset + sensitivity * (pressure - 150)
#   end
#   
#   def pressure_from_sensor_voltage(voltage)
#     (voltage - offset)/sensitivity + 150
#   end
#   
#   def sea_level_pressure_from_voltage(voltage, gain = self.gain)
#     sensor_voltage = reference + (voltage - reference)/gain
#     convert_to_sea_level(pressure_from_sensor_voltage(sensor_voltage))    
#   end
#   
#   def pressure_conversion_factor
#     standard_temperature, lapse_rate, gas_constant, molar_mass, gravity = 288.15, -0.0065, 8.31432, 0.0289644, 9.80665
#     (standard_temperature/(standard_temperature + lapse_rate * altitude)) ** (gravity * molar_mass/(gas_constant * lapse_rate))
#   end
#     
#   def convert_from_sea_level(pressure)
#     pressure * pressure_conversion_factor
#   end
#   
#   def convert_to_sea_level(pressure)
#     pressure / pressure_conversion_factor
#   end
#   
#   private
#   
#   def normalised_vad
#     device.oversample(:Vad, oversample) * 5.1 / device.oversample(:Vdd, oversample)
#   end
#   
#   def calibrate_to(target_voltage, error)
#     voltages = [ normalised_vad ] * 10
#     until voltages.all? { |voltage| (voltage - target_voltage).abs < error }
#       sleep 0.5
#       voltages.shift
#       voltages << normalised_vad
#       print "\r%+1.4f" % (voltages.last - target_voltage) # adapt number of decimal places according to error..?
#     end
#     voltages.last
#   end
#     
#   def device_is_ds2438
#     errors.add_to_base("device should be a DS2438") unless device.try(:read, :type) == "DS2438"
#   rescue SystemCallError, OneWire::BadRead, OneWire::ShortRead => e
#     errors.add_to_base("could not verify the one-wire device (#{e.message.downcase})")
#   end
# end
