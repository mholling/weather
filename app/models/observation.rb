class Observation < ActiveRecord::Base
  extend MeteorologicalDay

  belongs_to :instrument
  
  validates_presence_of :instrument
  validates_presence_of :value
  validates_presence_of :time
  
  named_scope :chronological, :order => :time
  named_scope :during, lambda { |interval| { :conditions => { :time => interval.utc } } }
  
  class << self
    def generate_meteorological_dates!
      find_each do |observation|
        observation.update_attributes(:meteorological_date => meteorological_date_for(observation.time))
      end
    end
  end
end
