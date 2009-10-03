class AddPositionToScale < ActiveRecord::Migration
  def self.up
    add_column :scales, :position, :integer
  end

  def self.down
    remove_column :scales, :position
  end
end
