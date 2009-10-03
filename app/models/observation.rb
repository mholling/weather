class Observation < ActiveRecord::Base
  extend MeteorologicalDay
  
  belongs_to :instrument
  
  validates_presence_of :instrument
  validates_presence_of :value
  
  named_scope :chronological, :order => :time
  named_scope :during, lambda { |interval| { :conditions => { :time => interval.utc } } }
  # named_scope :day_of, lambda { |observation| { :conditions => { :time => meteorological_day_of(observation.time) } } }
end
