#!/usr/bin/env ruby

### BEGIN INIT INFO
# Provides:          weather.rb
# Required-Start:    owserver $local_fs $named
# Required-Stop:     owserver $local_fs $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start weather logging daemon at boot time
# Description:       Enable weather logging service for the weather station application.
### END INIT INFO

require 'rubygems'
require 'daemons'

Daemons.run_proc('weather.rb', :dir_mode => :system, :multiple => false, :backtrace => true) do
  ENV["RAILS_ENV"] = ARGV.grep(/development|production/).first || "production"

  require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")
  
  Rails.logger.auto_flushing = 1 if Rails.env.development?
    
  Signal.trap("TERM") do
    raise Instrument::TerminateException
  end

  Instrument.observe!
end
