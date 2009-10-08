class FillScalableTypes < ActiveRecord::Migration
  def self.up
    Scaling.all.each do |scaling|
      scaling.update_attribute(:scalable_type, Chart.name)
    end
  end

  def self.down
  end
end
