class Observation < ActiveRecord::Base
  extend MeteorologicalDay
  
  belongs_to :instrument
  
  validates_presence_of :instrument
  validates_presence_of :value
  
  named_scope :chronological, :order => :created_at
  named_scope :during, lambda { |interval| { :conditions => { :created_at => interval.utc } } }
  # named_scope :day_of, lambda { |observation| { :conditions => { :created_at => meteorological_day_of(observation.created_at) } } }
end
