class Scaling < ActiveRecord::Base
  belongs_to :chart
  belongs_to :scale
  
  validates_presence_of :chart
  validates_presence_of :scale
  
  list_by :position, :scope => :scale_id
  
  def options(date)
    (APP_CONFIG["flot"] || {}).deep_merge(scale.options(date)).deep_merge(chart.options)
  end
  
  def data(date)
    chart.data(scale.interval(date))
  end
end
