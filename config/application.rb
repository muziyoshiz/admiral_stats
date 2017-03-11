require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AdmiralStats
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.time_zone = 'Tokyo'

    # Insert CORS request headers for API responses
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        # Access-Control-Allow-Origin: (Origin に書かれたものをそのまま返す)
        origins '*'

        # Access-Control-Allow-Methods: GET, POST, OPTIONS
        # Access-Control-Allow-Headers: (OPTIONS に対してのみ Access-Control-Request-Headers に書かれたものをそのまま返す)
        # Access-Control-Max-Age: 3600
        resource '/api/*',
                 :methods => [:get, :post, :options],
                 :headers => :any,
                 :max_age => 3600
      end
    end
  end
end
