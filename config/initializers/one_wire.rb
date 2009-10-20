APP_CONFIG["one_wire"].each { |key, value| OneWire::Config[key] = value } unless Rails.env.demo?
