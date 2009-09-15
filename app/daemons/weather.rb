#!/usr/bin/env ruby
require 'rubygems'
require 'daemons'

Daemons.run_proc('weather.rb', :dir_mode => :system, :multiple => false) do
  ENV["RAILS_ENV"] = ARGV.grep(/development|production/).first || "production"

  require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")
  Rails.logger.auto_flushing = 1 if Rails.env.development?
    
  Signal.trap("TERM") do
    raise Instrument::TerminateException
  end

  Instrument.observe!
end
