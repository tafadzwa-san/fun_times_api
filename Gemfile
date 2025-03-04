source "https://rubygems.org"

group :default do
  gem "rails", "~> 8.0.1"
  gem "puma", ">= 5.0"
  gem "tzinfo-data", platforms: %i[ windows jruby ]
  gem "solid_cache"
  gem "solid_queue"
  gem "solid_cable"
  gem "bootsnap", require: false
  gem "kamal", require: false
  gem "thruster", require: false
  gem "pg"
  gem "graphql"
  gem "sidekiq"
  gem "devise"
  gem "jwt"
  gem "omniauth-auth0"
  gem "rack-cors"
  gem "sorbet-runtime"
  gem "tapioca", require: false
  gem "devise-jwt"
end

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "rubocop-rails-omakase", require: false
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "dotenv-rails"
  gem "sorbet"
end
