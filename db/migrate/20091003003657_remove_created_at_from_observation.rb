class RemoveCreatedAtFromObservation < ActiveRecord::Migration
  def self.up
    remove_column :observations, :created_at
  end

  def self.down
    add_column :observations, :created_at, :datetime
  end
end
