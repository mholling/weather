class CreateChartings < ActiveRecord::Migration
  def self.up
    create_table :chartings do |t|
      t.references :chart
      t.references :instrument
      t.text :config

      t.timestamps
    end
  end

  def self.down
    drop_table :chartings
  end
end
