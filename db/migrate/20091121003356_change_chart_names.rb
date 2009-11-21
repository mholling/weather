class ChangeChartNames < ActiveRecord::Migration
  def self.up
    Chart.connection.execute("UPDATE charts SET type='DailyExtremaChart' WHERE type='DailyTemperaturesChart'")
    Chart.connection.execute("UPDATE charts SET type='TimeSeriesChart' WHERE type='TemperatureChart'")
  end

  def self.down
    Chart.connection.execute("UPDATE charts SET type='DailyTemperaturesChart' WHERE type='DailyExtremaChart'")
    Chart.connection.execute("UPDATE charts SET type='TemperatureChart' WHERE type='TimeSeriesChart'")
  end
end
