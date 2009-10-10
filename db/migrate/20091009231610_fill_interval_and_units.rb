class FillIntervalAndUnits < ActiveRecord::Migration
  def self.up
    Scale.all.each do |scale|
      scale.interval = scale.config.delete("interval")
      scale.units = scale.config.delete("units")
      scale.save
    end
  end

  def self.down
    Scale.all.each do |scale|
      scale.config["interval"] = scale.interval
      scale.config["units"] = scale.units
      scale.save
    end
  end
end
