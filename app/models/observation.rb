class Observation < ActiveRecord::Base
  belongs_to :instrument
  
  validates_presence_of :value
  
  named_scope :chronological, :order => :created_at
end
