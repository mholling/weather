class Scaling < ActiveRecord::Base
  belongs_to :scale
  belongs_to :scalable, :polymorphic => true
  belongs_to :chart, :class_name => Chart.name, :foreign_key => :scalable_id
  belongs_to :statistic, :class_name => Statistic.name, :foreign_key => :scalable_id
  
  validates_presence_of :scalable_id
  validates_presence_of :scale
  
  list_by :position, :scope => [ :scale_id, :scalable_type ]
  
  named_scope :for, lambda { |klass| { :conditions => { :scalable_type => klass.name } } }
  
  def options_for(date)
    (APP_CONFIG["flot"] || {}).deep_merge(scale.options_for(date)).deep_merge(chart.options)
  end
  
  def data(date)
    case scalable
    when Chart
      chart.data(scale.interval_for(date))
    when Statistic
      statistic.data(scale.interval_for(date))
    end
  end
end
