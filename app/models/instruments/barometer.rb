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
  
  %w{altitude oversample sensitivity offset reference gain gradient intercept last_calibrated_at}.each do |attribute|
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
    
    current_pressure = if options[:use_instrument]
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
      
      self.last_calibrated_at = Time.zone.now
      save
      puts "Setup complete. #{calibration_information}"
    rescue IRB::Abort
      reload
      puts "Aborted setup, weather daemon currently stopped!"
    end
  end
  
  def setup_again!
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
  
  def pressure_from_output_voltage(voltage)
    Pressure.new(intercept + gradient * voltage, altitude)
  end

  def normalised_vad
    samples, values = (2**(2*oversample)).round, []
    samples.times { values << device.read(:VAD).to_f * 5.1 / device.read(:VDD).to_f }
    median = values.sort[samples / 2]
    values.reject! { |value| (value - median).abs > 0.05 }
    values.sum / values.length
  end
  
  def calibration_information
    strings = []
    strings << "Lowest Pressure: %.1f hPa" % Pressure.new(intercept + gradient * 1.5, altitude).to_sea_level
    strings << "Highest Pressure: %.1f hPa" % Pressure.new(intercept + gradient * 4.9, altitude).to_sea_level
    strings << "Resolution: %.4f hPa" % Pressure.new(gradient * 0.01, altitude).to_sea_level
    strings << "Offset Voltage: %.4f V" % offset
    strings.join("; ")
  end

  def calibrate_to!(web_scraper)
    # TODO: add code to use updated_at for when #setup! was last called?
    after = last_calibrated_at || observations.with_value.chronological.first.time - 1.second
    puts "Calibrating for observations back to #{after.localtime}."
    
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
    r = (sums.n * sums.vp - sums.v * sums.p)/((sums.n * sums.v2 - sums.v**2) * (sums.n * sums.p2 - sums.p**2))**0.5
    puts "Statistics for calibration: %i observations, %1.3f hPa mean, %1.3f hPa standard deviation, %1.5f correlation." % [ v_p.length, Pressure.new(mean, altitude).to_sea_level, Pressure.new(sd, altitude).to_sea_level, r ]
    
    Instrument.stop_observations!
    
    updated_observations = observations.with_value.after(after).chronological.all
    voltages = updated_observations.map do |observation|
      output_voltage_from_pressure(Pressure.new(observation.value, 0.0))
    end
    
    puts "(Before) #{calibration_information}"
    
    self.gradient  = (sums.n * sums.vp - sums.v * sums.p )/(sums.n * sums.v2 - sums.v * sums.v)
    self.intercept = (sums.p * sums.v2 - sums.v * sums.vp)/(sums.n * sums.v2 - sums.v * sums.v)

    self.gain = 1.0 / (sensitivity * gradient)
    self.offset = reference * (gain - 1.0) / gain - (intercept - 150.0) * sensitivity

    puts " (After) #{calibration_information}"

    updated_observations.zip(voltages).each do |observation, voltage|
      observation.value = pressure_from_output_voltage(voltage).to_sea_level.to_f
    end

    print "Enter y to update calibration for the barometer: "
    if gets =~ /^y/i
      self.last_calibrated_at = updated_observations.last.time
      ActiveRecord::Base.transaction do
        save
        updated_observations.each(&:save)
      end
      puts "New sensor calibration saved. (You may wish to re-adjust gain if the offset voltage changed.)"
    else
      reload
      Instrument.restart_observations!
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
