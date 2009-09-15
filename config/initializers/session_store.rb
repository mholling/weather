# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_weather_session',
  :secret      => 'b5536f16c233e0b20ab03761de799c2da50ec6c68218066de3a9370b5ec3ce97d34a53ef65875cc0e0ae9835a564b41a94222de170dc75906b5b659454429067'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
