class RemoveUpdatedAtFromObservation < ActiveRecord::Migration
  def self.up
    remove_column :observations, :updated_at
  end

  def self.down
    add_column :observations, :updated_at, :datetime
  end
end
