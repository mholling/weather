class Device < ActiveRecord::Base
  validates_format_of :address, :with => /^[0-9A-F]{16}$/
  validates_uniqueness_of :address
    
  def one_wire_device
    OneWire::Device.new(address, :uncached => true)
  end  
  private :one_wire_device
  
  delegate :present?, :read, :write, :dir, :to => :one_wire_device
  
  def oversample(attribute, bits)
    n, sum = 2**(2*bits), 0
    n.times { sum += read(attribute) }
    sum / n
  end
end
