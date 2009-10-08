class AddScalableTypeToScalings < ActiveRecord::Migration
  def self.up
    add_column :scalings, :scalable_type, :string
    rename_column :scalings, :chart_id, :scalable_id
  end

  def self.down
    remove_column :scalings, :scalable_type
    rename_column :scalings, :scalable_id, :chart_id
  end
end
