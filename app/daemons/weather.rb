ENV["RAILS_ENV"] = ARGV.grep(/development|production/).first || "production"

require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

Rails.logger.auto_flushing = 1 if Rails.env.development?

Signal.trap("TERM") do
  raise Instrument::TerminateException
end

Instrument.observe!
