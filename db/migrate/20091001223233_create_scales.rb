class CreateScales < ActiveRecord::Migration
  def self.up
    create_table :scales do |t|
      t.string :name
      t.text :config

      t.timestamps
    end
  end

  def self.down
    drop_table :scales
  end
end
