class Component < ActiveRecord::Base
  belongs_to :device
  belongs_to :instrument
  
  validates_presence_of :device
  validates_presence_of :instrument
  
  serialize :config, Hash
  
  def after_initialize
    self.config ||= {}
  end
end
