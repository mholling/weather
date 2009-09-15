class CreateObservations < ActiveRecord::Migration
  def self.up
    create_table :observations do |t|
      t.references :instrument
      t.float :value

      t.timestamps
    end
  end

  def self.down
    drop_table :observations
  end
end
