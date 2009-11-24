class Instrument < ActiveRecord::Base
  class TerminateException < Exception; end
  has_many :components
  has_many :devices, :through => :components
  has_one :device, :through => :components
  
  has_many :observations
  
  has_many :chartings, :dependent => :destroy
  has_many :charts, :through => :chartings
  
  has_many :variables, :dependent => :destroy
  has_many :statistics, :through => :variables  
  
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
  
  def start!
    observations.create!(:value => nil, :time => Time.zone.now)
  end
  
  def observe!
    sleep [ time - Time.zone.now, 0 ].max
    if value = self.read!
      observations.create(:value => value.to_f, :time => value.respond_to?(:to_time) ? value.to_time : Time.zone.now)
      Rails.logger.debug "#{Time.zone.now} #{description.humanize} observed #{value}"
    end
  rescue SystemCallError, OneWire::BadRead, OneWire::ShortRead => e
    Rails.logger.info "#{Time.zone.now} Problem reading #{description.downcase}: #{e.message.downcase}"
    raise e
  ensure
    while time < Time.zone.now
      self.time += interval
    end
  end
  
  def description
    "#{self.class.name.underscore.humanize} (#{name.blank? ? id : name})"
  end
  
  def default_interval
    config['interval'] || APP_CONFIG['interval'] || 60
  end
  
  private
  
  attr_writer :time
  attr_accessor :interval
      
  class << self    
    def observe!
      Rails.logger.info "#{Time.zone.now} Starting observations."
      instruments = active.all(:include => :devices)
      instruments.each(&:start!)
      begin
        while true do
          instruments.sort!
          until instruments.first.due?
            sleep 1
          end
          instruments.first.observe!
        end
      rescue Errno::ECONNABORTED, Errno::ECONNRESET, Errno::ETIMEDOUT, Errno::ECONNREFUSED
        Rails.logger.info "#{Time.zone.now} Owserver down."
        until OneWire::Transaction.ping
          sleep APP_CONFIG['interval'] || 60
        end
        Rails.logger.info "#{Time.zone.now} Owserver back up."
        instruments.each(&:start!)
        retry
      rescue SystemCallError, OneWire::BadRead, OneWire::ShortRead => e
        retry
      end
    rescue TerminateException
      Rails.logger.info "#{Time.zone.now} Stopping observations."
    end
    
    [ "stop_observations", "restart_observations" ].each do |method|
      define_method "#{method}!" do
        if APP_CONFIG.has_key?(method)
          `#{APP_CONFIG[method]}`
          $?.success? ?
            Rails.logger.info("#{Time.zone.now} Weather daemon: attempt to #{method.humanize.downcase} succeeded.") :
            Rails.logger.error("#{Time.zone.now} Weather daemon: attempt to #{method.humanize.downcase} failed.")
        end
      end
    end
  end
end
