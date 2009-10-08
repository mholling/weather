class FillPositions < ActiveRecord::Migration
  def self.up
    Scaling.scoped(:order => :created_at).group_by(&:scale).each do |scale, scalings|
      scalings.map(&:id).each_with_index do |id, index|
        Scaling.update_all("position = #{index}", :id => id)
      end
    end
  end

  def self.down
  end
end
