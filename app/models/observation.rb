class Observation < ActiveRecord::Base
  extend MeteorologicalDay

  belongs_to :instrument
  
  validates_presence_of :instrument
  validates_presence_of :time
  validates_presence_of :meteorological_date
  
  named_scope :chronological, :order => :time
  named_scope :during, lambda { |interval| { :conditions => { :time => interval.utc } } }
  named_scope :with_value, :conditions => [ "value IS NOT :nil", { :nil => nil } ]
  
  before_validation :set_meteorological_date
    
  def set_meteorological_date
    self.meteorological_date = Observation.meteorological_date_for(time) if time
  end
  
  class << self
    def generate_meteorological_dates!
      find_each do |observation|
        observation.set_meteorological_date
      end
    end
  end
end
