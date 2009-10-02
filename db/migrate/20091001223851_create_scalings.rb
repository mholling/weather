class CreateScalings < ActiveRecord::Migration
  def self.up
    create_table :scalings do |t|
      t.references :chart
      t.references :scale
      t.integer :position

      t.timestamps
    end
  end

  def self.down
    drop_table :scalings
  end
end
