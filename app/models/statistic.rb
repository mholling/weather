class Statistic < ActiveRecord::Base
  has_many :variables, :dependent => :destroy
  has_many :instruments, :through => :variables
  has_one :instrument, :through => :variables
  
  has_many :scalings, :dependent => :destroy, :as => :scalable
  has_many :scales, :through => :scalings
  
  validates_size_of :instruments, :minimum => 1

  serialize :config, Hash
  
  def after_initialize
    self.config ||= {}
  end
end
