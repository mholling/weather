class FillScalableTypes < ActiveRecord::Migration
  def self.up
    Scaling.all.each do |scaling|
      Scaling.update_all("scalable_type = '#{Chart.name.underscore}'", :id => scaling.id)
      # scaling.update_attribute(:scalable_type, Chart.name)
    end
  end

  def self.down
  end
end
