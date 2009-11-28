class Pressure
  STANDARD_TEMPERATURE, LAPSE_RATE, GAS_CONSTANT, MOLAR_MASS, GRAVITY = 288.15, -0.0065, 8.31432, 0.0289644, 9.80665

  attr_reader :value, :altitude
  
  def initialize(value, altitude)
    @value, @altitude = value, altitude
  end
  
  def to_sea_level
    to_altitude(0.0)
  end
  
  def to_altitude(altitude)
    Pressure.new(value * Pressure.conversion_factor(altitude) / Pressure.conversion_factor(@altitude), altitude)
  end
  
  delegate :to_f, :to => :value
  
  def self.conversion_factor(altitude)
    altitude.zero? ? 1.0 : (STANDARD_TEMPERATURE/(STANDARD_TEMPERATURE + LAPSE_RATE * altitude)) ** (GRAVITY * MOLAR_MASS/(GAS_CONSTANT * LAPSE_RATE))
  end
end

class Barometer < Instrument
  
  validates_size_of :devices, :is => 1
  validate :device_is_ds2438
  
  def read!
    pressure_from_output_voltage(normalised_vad).to_sea_level.to_f
  end
  
  %w{altitude oversample sensitivity offset reference gain gradient intercept last_adjusted_at last_calibrated_at}.each do |attribute|
    define_method "#{attribute}=" do |value|
      self.config[attribute] = value
    end
  
    define_method attribute do
      self.config[attribute]
    end
  end
  
  def setup!(options = {})
    unless valid?
      puts "Can't set up the barometer yet!"
      puts errors.map { |attribute, error| "#{attribute}: #{error}" }
      return
    end
    
    self.sensitivity ||= 0.0046
    self.offset ||= 0.204
    
    unless options[:use_instrument]
      print "Enter altitude in metres: "
      self.altitude = gets.to_f
    end
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
    
    current_pressure = if options[:use_instrument]
      puts "Reading current pressure..."
      pressure_from_output_voltage(normalised_vad)
    else
      print "Enter the current MSL pressure in hPa: "
      Pressure.new(gets.to_f, 0.0)
    end
    
    begin
      Instrument.stop_observations!
    
      self.reference = adjust_reference(target_reference)
      self.gain = adjust_gain(target_gain, current_pressure)
    
      self.gradient = 1.0 / (sensitivity * gain)
      self.intercept = 150.0 + (reference * (gain - 1.0) / gain - offset) / sensitivity
      
      self.last_adjusted_at = Time.zone.now
      self.last_calibrated_at = nil
      puts "Setup complete. #{calibration_information}"
      save
    rescue IRB::Abort
      reload
      puts "Aborted setup, weather daemon currently stopped!"
    end
  end
  
  def adjust!
    setup!(:use_instrument => true)
  end
  
  def adjust_reference(target_reference)
    print "Set jumper to calibration position and press enter to begin reference calibration (s to skip): "
    return target_reference if gets =~ /^s/
    
    returning adjust_vad_to(target_reference) do |actual_reference|
      puts "Reference voltage calibrated as %1.4f volts." % actual_reference
    end
  end
  
  def adjust_gain(target_gain, current_pressure)
    reference_pressure = pressure_from_sensor_voltage(reference)
    prompt = (current_pressure.to_sea_level.to_f - reference_pressure.to_sea_level.to_f).abs < 5.0 ?
      "(Current pressure is %1.1f hPa, reference pressure is %1.1f hPa; WARNING: results could be poor.)" :
      "(Current pressure is %1.1f hPa, reference pressure is %1.1f hPa.)"
    puts prompt % [ current_pressure.to_sea_level, reference_pressure.to_sea_level ]
    
    print "Set jumper to normal position and press enter to begin gain calibration: "
    gets
    
    sensor_voltage = sensor_voltage_from_pressure(current_pressure)
    target_voltage = target_gain * (sensor_voltage - reference) + reference
    
    actual_voltage = adjust_vad_to(target_voltage)
    
    returning (actual_voltage - reference)/(sensor_voltage - reference) do |actual_gain|
      puts "Gain calibrated as %1.4f." % actual_gain
    end
  end

  def adjust_vad_to(target_voltage)
    begin
      print "Please wait, reading voltage..."
      actual_voltage = normalised_vad
      print "\rtarget: %1.4f, actual: %1.4f, error: %+1.4f. Return to repeat or y to end: " % [ target_voltage, actual_voltage, (actual_voltage - target_voltage) ]
    end until gets =~ /^y/i
    actual_voltage
  end
  
  def sensor_voltage_from_pressure(pressure)
    offset + sensitivity * (pressure.to_altitude(altitude).to_f - 150.0)
  end
  
  def pressure_from_sensor_voltage(voltage)
    Pressure.new((voltage - offset)/sensitivity + 150.0, altitude)
  end
    
  def output_voltage_from_pressure(pressure)
    (pressure.to_altitude(altitude).to_f - intercept)/gradient
  end
  
  def pressure_from_output_voltage(voltage, intercept = self.intercept, gradient = self.gradient)
    Pressure.new(intercept + gradient * voltage, altitude)
  end

  def normalised_vad
    samples, values = (2**(2*oversample)).round, []
    samples.times { values << device.read(:VAD).to_f * 5.1 / device.read(:VDD).to_f }
    median = values.sort[samples / 2]
    values.reject! { |value| (value - median).abs > 0.05 }
    values.sum / values.length
  end
  
  def calibration_information(intercept = self.intercept, gradient = self.gradient, offset = self.offset)
    strings = []
    strings << "Lowest Pressure: %.1f hPa" % Pressure.new(intercept + gradient * 1.5, altitude).to_sea_level
    strings << "Highest Pressure: %.1f hPa" % Pressure.new(intercept + gradient * 4.9, altitude).to_sea_level
    strings << "Resolution: %.4f hPa" % Pressure.new(gradient * 0.01, altitude).to_sea_level
    strings << "Offset Voltage: %.4f V" % offset
    strings.join("; ")
  end

  def calibrate_to!(web_scraper, options = {})
    after = [ options[:after] || last_calibrated_at, last_adjusted_at ].compact.max
    after ||= observations.with_value.chronological.first.time - 1.second
    puts "Calibrating using observations back to #{after.localtime}."
    
    v_p = web_scraper.matched_observations_for(self, :margin => 5.minutes, :after => after).map do |observation_pair|
      observation_pair.map { |observation| Pressure.new(observation.value, 0.0) }
    end.map do |measured_pressure, scraped_pressure|
      [ output_voltage_from_pressure(measured_pressure), scraped_pressure.to_altitude(altitude).value ]
    end
    
    if v_p.length < 2
      puts "Not enough scraped pressure values to calibrate from!"
      return
    end
    
    sums = v_p.inject(OpenStruct.new(:v => 0.0, :v2 => 0.0, :p => 0.0, :p2 => 0.0, :vp => 0.0, :n => 0)) do |sums, (v, p)|
      sums.v += v; sums.v2 += v * v; sums.p += p; sums.p2 += p * p; sums.vp += v * p; sums.n += 1
      sums
    end
    
    mean = sums.p / sums.n
    sd = (sums.p2 / sums.n - mean**2)**0.5
    puts "Scraped data: %i observations, %1.1f hPa mean, %1.3f hPa standard deviation." % [ v_p.length, Pressure.new(mean, altitude).to_sea_level, Pressure.new(sd, altitude).to_sea_level ]
    
    new_gradient  = (sums.n * sums.vp - sums.v * sums.p )/(sums.n * sums.v2 - sums.v * sums.v)
    new_intercept = (sums.p * sums.v2 - sums.v * sums.vp)/(sums.n * sums.v2 - sums.v * sums.v)

    r = (sums.n * sums.vp - sums.v * sums.p)/((sums.n * sums.v2 - sums.v**2) * (sums.n * sums.p2 - sums.p**2))**0.5
    mse = (new_gradient * new_gradient * sums.v2 + sums.n * new_intercept * new_intercept + sums.p2 + 2 * new_gradient * new_intercept * sums.v - 2 * new_intercept * sums.p - 2 * new_gradient * sums.vp) / sums.n
    puts "Regression results: %1.5f correlation, %1.3f hPa RMS error." % [ r, mse**0.5 ]

    new_gain = 1.0 / (sensitivity * new_gradient)
    new_offset = reference * (new_gain - 1.0) / new_gain - (new_intercept - 150.0) * sensitivity  
    
    puts "(Before) #{calibration_information}"
    puts " (After) #{calibration_information(new_intercept, new_gradient, new_offset)}"
      
    print "Enter y to save new calibration for the barometer, or return to cancel: "
    if gets =~ /^y/i
      print "Enter y to recalculate past observations back to #{after.localtime}, or return to skip: "
      recalculate = gets =~ /^y/i
      Instrument.stop_observations!
      ActiveRecord::Base.transaction do
        observations.with_value.after(after).find_each do |observation|
          voltage = output_voltage_from_pressure(Pressure.new(observation.value, 0.0))
          observation.update_attribute(:value, pressure_from_output_voltage(voltage, new_intercept, new_gradient).to_sea_level.to_f)
        end if recalculate
        self.gradient, self.intercept, self.gain, self.offset = new_gradient, new_intercept, new_gain, new_offset
        self.last_calibrated_at = Time.zone.now
        save
      end
      puts "Calibration complete. (You may wish to re-adjust gain if the offset voltage changed.)"
    else
      puts "Calibration cancelled."
    end
  end
    
  protected
  
  def device_is_ds2438
    errors.add_to_base("device should be a DS2438") unless devices.first.try(:read, :type) == "DS2438"
  rescue SystemCallError, OneWire::BadRead, OneWire::ShortRead => e
    errors.add_to_base("could not verify the one-wire device (#{e.message.downcase})")
  end
end
