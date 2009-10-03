class FillMeteorologicalDatesFromTimes < ActiveRecord::Migration
  def self.up
    Observation.generate_meteorological_dates!
  end

  def self.down
  end
end
