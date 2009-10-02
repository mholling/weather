class Scaling < ActiveRecord::Base
  belongs_to :chart
  belongs_to :scale
  
  validates_presence_of :chart
  validates_presence_of :scale
  
  def options(date)
    (APP_CONFIG["jqplot"] || {}).deep_merge(scale.options(date)).deep_merge(chart.options)
  end
  
  def data(date)
    chart.data(scale.interval(date))
  end
end
