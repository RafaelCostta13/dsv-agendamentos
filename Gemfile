source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails", "8.1.4.1"
gem "propshaft", "1.3.2"
gem "pg", "~> 1.6"
gem "puma", "8.0.5"
gem "bcrypt", "3.1.22"
gem "rqrcode", "3.2.0"
gem "caxlsx", "4.5.0", require: "axlsx"

group :development, :test do
  gem "minitest", "~> 5.25"
  gem "brakeman", "8.1.1", require: false
  gem "bundler-audit", "0.9.3", require: false
  gem "rubocop-rails-omakase", "1.1.0", require: false
end

group :test do
  gem "roo", "3.0.0", require: false
end
