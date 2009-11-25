require 'ostruct'

class WebScraper < Instrument
  validate :config_ok
  
  def default_interval
    config['interval'] || 60*30
  end
  
  def read!
    time_selector, value_selector = config['time-selector'], config['value-selector']
    uri = URI.parse(config['url'])

    @scraper ||= Scraper.define do
      process_first time_selector, :time => :text
      process_first value_selector, :value => :text
      result :time, :value
    end
    
    scraped = @scraper.scrape(uri)
    begin
      time = Time.zone.parse(scraped.time)
      to_f = Float(scraped.value)
    rescue ArgumentError, TypeError
      return nil
    end
    return nil unless time && observations.chronological.last && observations.chronological.last.time < time
    
    OpenStruct.new(:to_f => to_f, :to_time => time)
  rescue Scraper::Reader::HTTPError, Scraper::Reader::HTMLParseError => e
    Rails.logger.error "#{Time.zone.now} Couldn't scrape from #{uri} (#{e.message})"
    nil
  end
  
  def matched_observations_for(instrument, options = {})
    options[:after] ||= instrument.observations.with_value.chronological.first.time - 1.second
    options[:margin] ||= 5.minutes
    observations.with_value.after([ options[:after], updated_at ].max).map do |scraped_observation|
      nearby_observations = instrument.observations.with_time(scraped_observation.time - options[:margin] .. scraped_observation.time + options[:margin])
      nearest_observation = nearby_observations.inject do |closest_observation, observation|
        (closest_observation.time - scraped_observation.time).abs < (observation.time - scraped_observation.time).abs ? closest_observation : observation
      end
      nearest_observation ? [ nearest_observation, scraped_observation ] : nil
    end.compact
  end

  protected
  
  def config_ok
    errors.add(:config, "must have config['url'] specified") unless config['url']
    errors.add(:config, "must have config['time-selector'] specified") unless config['time-selector']
    errors.add(:config, "must have config['value-selector'] specified") unless config['value-selector']
    
    # # # Sample config:
    # config['url'] = "http://www.bom.gov.au/products/IDN60801/IDN60801.94925.shtml"
    # config['time-selector'] = "table.tabledata > tbody > tr.rowleftcolumn > td:first-of-type"
    # config['value-selector'] = "table.tabledata > tbody > tr.rowleftcolumn > td:nth-of-type(12)"
  end
end