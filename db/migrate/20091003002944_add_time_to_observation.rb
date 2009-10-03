class AddTimeToObservation < ActiveRecord::Migration
  def self.up
    add_column :observations, :time, :datetime
  end

  def self.down
    remove_column :observations, :time
  end
end
