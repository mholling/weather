class Variable < ActiveRecord::Base
  belongs_to :statistic
  belongs_to :instrument
  
  validates_presence_of :statistic
  validates_presence_of :instrument
  
  serialize :config, Hash
  
  def after_initialize
    self.config ||= {}
  end
end
