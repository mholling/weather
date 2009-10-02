class Charting < ActiveRecord::Base
  belongs_to :chart
  belongs_to :instrument
  
  validates_presence_of :chart
  validates_presence_of :instrument
  
  serialize :config, Hash
  
  def after_initialize
    self.config ||= {}
  end
end
