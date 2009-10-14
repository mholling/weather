class Thermometer < Instrument
  
  validates_size_of :devices, :is => 1
  validate :device_is_ds18b20
  
  def read!
    # value = Float(device.read(:temperature12))
    # @value = value unless @value == value
    Float(device.read(:temperature12))
  end
  
  private
    
  def device_is_ds18b20
    errors.add_to_base("device should be a DS18B20") unless device.try(:read, :type) == "DS18B20"
  rescue SystemCallError, OneWire::BadRead, OneWire::ShortRead => e
    errors.add_to_base("could not verify the one-wire device (#{e.message.downcase})")
  end
end