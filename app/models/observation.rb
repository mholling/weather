class Observation < ActiveRecord::Base
  belongs_to :instrument
  
  validates_presence_of :instrument
  validates_presence_of :time
  validates_presence_of :meteorological_date
  
  named_scope :chronological, :order => :time
  named_scope :with_meteorological_date, lambda { |dates| { :conditions => { :meteorological_date => dates } } }
  named_scope :after, lambda { |time| { :conditions => [ "time > :time", { :time => time.utc } ] } }
  named_scope :with_time, lambda { |times| { :conditions => { :time => times } } }
  named_scope :with_value, :conditions => [ "value IS NOT :nil", { :nil => nil } ]
  
  before_validation :set_meteorological_date
    
  def set_meteorological_date
    self.meteorological_date = time.to_meteorological_date if time
  end
  
  class << self
    def generate_meteorological_dates!
      find_each do |observation|
        observation.set_meteorological_date
      end
    end
  end
end
