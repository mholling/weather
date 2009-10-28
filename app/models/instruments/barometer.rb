class Barometer < Instrument
  
  validates_size_of :devices, :is => 1
  validate :device_is_ds2438
  
  def read!
    sea_level_pressure_from_voltage(device.oversample(:Vad, oversample))
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
      errors.each { |attribute, error| puts "#{attribute}: #{error}" }
      return
    end
    
    self.sensitivity = 0.0046
    self.offset = 0.204

    [ %w{altitude minimum_pressure maximum_pressure oversample}, %w{metres hPa hPa bits}, %w{to_f to_f to_f to_i} ].transpose.map do |attribute, units, convert|
      print "Enter #{attribute.humanize.downcase} in #{units}: "
      self.send "#{attribute}=", gets.send(convert)
    end

    voltages = [ minimum_pressure, maximum_pressure ].map do |pressure|
      convert_from_sea_level(pressure)
    end.map do |pressure|
      sensor_voltage_from_pressure(pressure)
    end

    target_gain = (4.9 - 1.5)/(voltages.max - voltages.min)
    target_reference = (target_gain * voltages.min - 1.5)/(target_gain - 1.0)

    print "Set output jumper to reference calibration position and press enter to begin reference calibration: "
    gets
    
    self.reference = calibrate_to(target_reference, 0.01)

    puts "Reference voltage calibrated. (Reference pressure is %.1f hPa.)" % sea_level_pressure_from_voltage(reference)
    
    print "Enter the current BOM pressure in hPa: "
    pressure = gets.to_f
    
    print "Set output jumper to normal position and press enter to begin gain calibration: "
    gets
    
    sensor_voltage = sensor_voltage_from_pressure(convert_from_sea_level(pressure))
    target_voltage = target_gain * (sensor_voltage - reference) + reference
    output_voltage = calibrate_to(target_voltage, 0.01)
    
    self.gain = (output_voltage - reference)/(sensor_voltage - reference)
    
    puts "Gain calibrated. (Calculated gain as %1.4f.)" % gain
    save
  end
  
  def sensor_voltage_from_pressure(pressure)
    vdd = device.read(:Vdd)
    (offset + sensitivity * (pressure - 150)) * vdd / 5.1
  end
  
  def pressure_from_sensor_voltage(voltage)
    vdd = device.read(:Vdd)
    ((5.1 * voltage / vdd) - offset)/sensitivity + 150
  end
  
  def sea_level_pressure_from_voltage(voltage)
    sensor_voltage = reference + (voltage - reference)/gain
    convert_to_sea_level(pressure_from_sensor_voltage(sensor_voltage))    
  end
  
  def pressure_conversion_factor
    standard_temperature = 288.15
    lapse_rate = -0.0065
    gas_constant = 8.31432
    molar_mass = 0.0289644
    gravity = 9.80665
    (standard_temperature/(standard_temperature + lapse_rate * altitude)) ** (gravity * molar_mass/(gas_constant * lapse_rate))
  end
    
  def convert_from_sea_level(pressure)
    pressure * pressure_conversion_factor
  end
  
  def convert_to_sea_level(pressure)
    pressure / pressure_conversion_factor
  end
  
  private
  
  def calibrate_to(target_voltage, error)
    voltages = [ device.oversample(:Vad, oversample) ] * 10
    until voltages.all? { |voltage| (voltage - target_voltage).abs < error }
      sleep 0.5
      voltages.shift
      voltages << device.oversample(:Vad, oversample)
      print "\r%+1.4f" % voltages.last - target_voltage # adapt number of decimal places according to error..?
    end
    voltages.last
  end
    
  def device_is_ds2438
    errors.add_to_base("device should be a DS2438") unless device.try(:read, :type) == "DS2438"
  rescue SystemCallError, OneWire::BadRead, OneWire::ShortRead => e
    errors.add_to_base("could not verify the one-wire device (#{e.message.downcase})")
  end
end
