class Scale < ActiveRecord::Base
  has_many :scalings, :dependent => :destroy
  has_many :charts, :through => :scalings, :source => :chart, :conditions => { "scalings.scalable_type" => Chart.name }
  has_many :statistics, :through => :scalings, :source => :statistic, :conditions => { "scalings.scalable_type" => Statistic.name }
  
  validates_inclusion_of :units, :in => [ "days", "weeks", "months", "years" ], :allow_nil => false
  validates_presence_of :interval
  
  list_by :position
  
  serialize :config, Hash
  
  def after_initialize
    self.config ||= {}
  end
  
  def interval_for(date)
    finish = date.send("end_of_#{units.singularize}").to_date
    start = finish - interval.send(units.pluralize) + 1.day
    (start..finish)
  end
  
  def options_for(date)
    # date_options = { "xaxis" => { "min" => interval_for(date).begin.to_js, "max" => interval_for(date).end.to_js } }
    date_options = { "xaxis" => { "min" => interval_for(date).begin.beginning_of_meteorological_day.to_js, "max" => interval_for(date).end.end_of_meteorological_day.to_js } }
    # TODO: this is good for the daily and weekly charts, but not quite right for the monthly/yearly charts...
    # (fix by setting those charts to return start of met. day instead of midnight?)
    self.class.options.deep_merge(config["flot"] || {}).deep_merge(date_options)
  end
  
  def self.config
    APP_CONFIG[name.underscore] || {}
  end
  
  def self.options
    config["flot"] || {}
  end
end
