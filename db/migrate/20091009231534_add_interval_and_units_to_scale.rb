class AddIntervalAndUnitsToScale < ActiveRecord::Migration
  def self.up
    add_column :scales, :interval, :integer
    add_column :scales, :units, :string
  end

  def self.down
    remove_column :scales, :units
    remove_column :scales, :interval
  end
end
