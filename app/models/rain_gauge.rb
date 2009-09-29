require 'digest/md5'

class RainGauge < Instrument
  class NoOldCountError < RuntimeError; end
  
  validates_size_of :devices, :is => 1
  validate :device_is_ds2423
  validate :config_ok
  
  def read!
    count = new_count()
    change = count - old_count()
    if change > 0
      self.interval = [ interval / change, 1 ].max if change > 1
      self.old_count = count
      change * config['per_tip']
    else
      self.interval = [ 1.1 * interval, default_interval ].min
      nil
    end
  end
  
  private
  
  def device
    devices.first
  end
  
  def device_is_ds2423
    errors.add_to_base("device should be a DS2423") unless device.try(:read, :type) == "DS2423"
  rescue SystemCallError => e
    errors.add_to_base("could not verify the one-wire device (#{e.message.downcase})")
  end
  
  def config_ok
    messages = []
    messages << "config['per_tip'] should be a positive number" unless config['per_tip'].is_a?(Numeric) && config['per_tip'] > 0
    messages << "config['counter'] should be 'A' or 'B'" unless [ "A", "B" ].include?(config['counter'])
    messages << "config['page'] should be between 0 and 15" unless (0..15).include?(config['page'])
    errors.add_to_base(messages.join(', ')) unless messages.empty?
  end
  
  def new_count
    Integer(device.read(count_attribute))
  end
  
  def old_count
    unpack(device.read(page_attribute))
  rescue NoOldCountError
    0
  end
  
  def old_count=(count)
    device.write(page_attribute, pack(count))
  end
  
  def count_attribute
    "counters.#{config['counter']}"
  end
  
  def page_attribute
    "pages/page.#{config['page']}"
  end
  
  def pack(number)
    digest = Digest::MD5.digest([ number ].pack("L"))
    [ number, digest ].pack("LA16x12")
  end
  
  def unpack(string)
    number, digest = string.unpack("LA16x12")
    raise NoOldCountError if digest != Digest::MD5.digest([ number ].pack("L"))
    number
  rescue ArgumentError
    raise NoOldCountError
  end
  
end