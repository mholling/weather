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
    return nil unless scraped.value && scraped.time
    time = Time.zone.parse(scraped.time)
    return nil unless time && time != @time
    @time = time
    
    OpenStruct.new(:to_f => scraped.value.to_f, :to_time => time)
  rescue Scraper::Reader::HTTPError, Scraper::Reader::HTMLParseError => e
    Rails.logger.error "#{Time.zone.now} Couldn't scrape from #{uri} (#{e.message})"
    nil
  end
  
  protected
  
  def config_ok
    errors.add(:config, "must have config['url'] specified") unless config['url']
    errors.add(:config, "must have config['time-selector'] specified") unless config['time-selector']
    errors.add(:config, "must have config['value-selector'] specified") unless config['value-selector']
    
    # # # Sample config:
    # config['url'] = "http://www.bom.gov.au/products/IDN60903/IDN60903.94925.shtml"
    # config['time-selector'] = "table.tabledata > tbody > tr.rowleftcolumn > td:first-of-type"
    # config['value-selector'] = "table.tabledata > tbody > tr.rowleftcolumn > td:nth-of-type(12)"
  end
end