class CreateVariables < ActiveRecord::Migration
  def self.up
    create_table :variables do |t|
      t.references :statistic
      t.references :instrument
      t.text :config

      t.timestamps
    end
  end

  def self.down
    drop_table :variables
  end
end
