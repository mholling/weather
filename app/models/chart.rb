class Chart < ActiveRecord::Base
  BATCH = 1000
  
  has_many :chartings
  has_many :instruments, :through => :chartings
  has_one :instrument, :through => :chartings
  has_many :scalings, :dependent => :destroy
  has_many :scales, :through => :scalings
  
  validates_size_of :instruments, :minimum => 1
  
  serialize :config, Hash
  
  def after_initialize
    self.config ||= {}
  end
  
  def options
    self.class.options.deep_merge(config["flot"] || {})
  end
  
  def self.config
    APP_CONFIG[name.underscore] || {}
  end
  
  def self.options
    config["flot"] || {}
  end
end
