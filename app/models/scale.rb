class Scale < ActiveRecord::Base
  has_many :scalings, :dependent => :destroy
  has_many :charts, :through => :scalings
  
  # TODO: improve the way the scales work?
  
  serialize :config, Hash
  
  def after_initialize
    self.config ||= {}
  end
  
  def interval(date)
    units = config["units"].downcase.pluralize
    finish = date.to_time.send("end_of_#{units.singularize}")
    start = (finish + 1.second) - config["interval"].send(units)
    (start..finish)
  end
  
  def options(date)
    date_options = { "xaxis" => { "min" => interval(date).begin.to_js, "max" => interval(date).end.to_js } }
    self.class.options.deep_merge(config["flot"] || {}).deep_merge(date_options)
  end
  
  def self.config
    APP_CONFIG[name.underscore] || {}
  end
  
  def self.options
    config["flot"] || {}
  end
end
