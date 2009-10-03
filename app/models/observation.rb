class Observation < ActiveRecord::Base
  belongs_to :instrument
  
  validates_presence_of :instrument
  validates_presence_of :value
  validates_presence_of :time
  
  named_scope :chronological, :order => :time
  named_scope :during, lambda { |interval| { :conditions => { :time => interval.utc } } }
end
