class AddMeteorologicalDateToObservations < ActiveRecord::Migration
  def self.up
    add_column :observations, :meteorological_date, :date
  end

  def self.down
    remove_column :observations, :meteorological_date
  end
end
