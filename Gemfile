source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.0', '>= 5.1.2'
# Use mysql as the database for Active Record
gem 'mysql2', '>= 0.3.18', '< 0.5'
# Use Puma as the app server
gem 'puma', '~> 3.0'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
# therubyracer の Ruby 2.4.0 対応は 0.12.3 以降
# https://stackoverflow.com/questions/41461977/after-ruby-2-4-upgrade-error-while-trying-to-load-the-gem-uglifier-bundler
gem 'therubyracer', '~> 0.12.3', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
# gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console'
  gem 'listen', '~> 3.0.5'

  # Spring が原因でクラスのロードや、環境変数のロードに失敗することがあったため、オフにした
  # クラスが増えて、開発に支障が出るくらいロード時間が長くなったら元に戻す
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem 'spring'
  # gem 'spring-watcher-listen', '~> 2.0.0'
end

# Group for deployment server in production environment
group :deployment do
  # Capistrano
  gem 'capistrano', '~> 3.1'
  gem 'capistrano-rails', '~> 1.1'
  gem 'capistrano-rvm'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Official Sass port of Bootstrap
gem 'bootstrap-sass', '~> 3.3.6'

gem 'jquery-datatables-rails', '~> 3.4.0'
# The gem version mirrors the included version of Highcharts
gem 'highcharts-rails', '~> 4.2.5'

gem 'admiral_stats_parser', '1.15.0'

# Ruby 2.4.1 で json gem v1.8.3 をビルドできない問題への対応 → gem 側の問題が解決したらこの行は削除する
# http://qiita.com/shinichinomura/items/41e03d7e4fa56841e654
gem 'json', github: 'flori/json', branch: 'v1.8'

# Twitter Oauth
gem 'omniauth'
gem 'omniauth-twitter'

# Google Analytics
gem 'google-analytics-rails', '1.1.0'

# Open Graph Protocol (OGP) Support
gem 'meta-tags'

# Sitemap Support
gem 'sitemap_generator'

# JWT (JSON Web Token)
gem 'jwt', '~> 1.5.6'

# Rack CORS Middleware for API (/api/*)
gem 'rack-cors', :require => 'rack/cors'

# clipboard.js
gem 'clipboard-rails', '~> 1.6.1'

# jquery.qrcode.js
gem 'jquery-qrcode-rails'

# For security update
gem 'nokogiri', '~> 1.8.1'
