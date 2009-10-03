class SwapObservationCreatedAtToTime < ActiveRecord::Migration
  def self.up
    Observation.find_each do |observation|
      observation.update_attributes(:time => observation.created_at)
    end
  end

  def self.down
    Observation.find_each do |observation|
      observation.update_attributes(:created_at => observation.time, :updated_at => observation.time)
    end
  end
end
