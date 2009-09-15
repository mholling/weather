class CreateComponents < ActiveRecord::Migration
  def self.up
    create_table :components do |t|
      t.references :device
      t.references :instrument
      t.text :config

      t.timestamps
    end
  end

  def self.down
    drop_table :components
  end
end
