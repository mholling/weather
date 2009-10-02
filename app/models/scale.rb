class Scale < ActiveRecord::Base
  has_many :scalings, :dependent => :destroy
  has_many :charts, :through => :scalings
  
  # TODO: add :interval column instead of having it in the config...
  
  serialize :config, Hash
  
  def after_initialize
    self.config ||= {}
  end
  
  def interval(date)
    finish = (date + 1.day).beginning_of_day
    start = finish - config["interval"].days
    (start...finish)
  end
  
  def options(date)
    date_options = { "axes" => { "xaxis" => { "min" => interval(date).begin.to_js, "max" => interval(date).end.to_js } } }
    self.class.options.deep_merge(config["jqplot"] || {}).deep_merge(date_options)
  end
  
  def self.config
    APP_CONFIG[name.underscore] || {}
  end
  
  def self.options
    config["jqplot"] || {}
  end
end
