class Instrument < ActiveRecord::Base
  class TerminateException < Exception; end
  has_many :components
  has_many :devices, :through => :components
  has_many :observations
  
  validates_associated :devices
  
  serialize :config, Hash
  
  named_scope :active, :conditions => { :active => true }
    
  def after_initialize
    self.config ||= {}
    self.time = Time.now
    self.interval = default_interval
  end
  
  attr_reader :time
      
  def <=>(other)
    time <=> other.time
  end
  
  def due?
    time <= Time.now
  end
  
  def observe!
    sleep [ time - Time.now, 0 ].max
    if value = self.read!
      observations.create(:value => value)
      Rails.logger.info("#{Time.now} #{description.humanize} observed #{value}")
    end
  rescue SystemCallError => e
    Rails.logger.error("#{Time.now} Problem reading #{description.downcase}: #{e.message.downcase}")
  ensure
    while time < Time.now
      self.time += interval
    end
  end
  
  private
  
  def description
    "#{self.class.name.underscore.humanize} (#{name.blank? ? id : name})"
  end
  
  def default_interval
    config['interval'] || 60
  end
  
  attr_writer :time
  attr_accessor :interval
      
  class << self    
    def observe!
      Rails.logger.info "#{Time.now} Starting observations."
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
      Rails.logger.info "#{Time.now} Stopping observations."
    end
  end
end
