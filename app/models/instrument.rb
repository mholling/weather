class Instrument < ActiveRecord::Base
  class TerminateException < Exception; end
  has_many :components
  has_many :devices, :through => :components
  has_one :device, :through => :components
  has_many :observations
  has_many :chartings
  has_many :charts, :through => :chartings
  
  
  validates_associated :devices
  
  serialize :config, Hash
  
  named_scope :active, :conditions => { :active => true }
    
  def after_initialize
    self.config ||= {}
    self.time = Time.zone.now
    self.interval = default_interval
  end
  
  attr_reader :time
      
  def <=>(other)
    time <=> other.time
  end
  
  def due?
    time <= Time.zone.now
  end
  
  def observe!
    sleep [ time - Time.zone.now, 0 ].max
    if values = self.read!
      [ values ].flatten.each do |value|
        observations.create(:value => value, :time => Time.zone.now)
        Rails.logger.info("#{Time.zone.now} #{description.humanize} observed #{value}")
      end
    end
  rescue SystemCallError => e
    Rails.logger.error("#{Time.zone.now} Problem reading #{description.downcase}: #{e.message.downcase}")
  ensure
    while time < Time.zone.now
      self.time += interval
    end
  end
  
  def description
    "#{self.class.name.underscore.humanize} (#{name.blank? ? id : name})"
  end
  
  def default_interval
    config['interval'] || 60
  end
  
  private
  
  attr_writer :time
  attr_accessor :interval
      
  class << self    
    def observe!
      Rails.logger.info "#{Time.zone.now} Starting observations."
      instruments = active.all(:include => :devices)
      while true do
        instruments.sort!
        until instruments.first.due?
          sleep 1
        end
        instruments.first.observe!
        # TODO: touch a file to indicate alive to monit?
      end
    rescue TerminateException
      Rails.logger.info "#{Time.zone.now} Stopping observations."
    end
  end
end
