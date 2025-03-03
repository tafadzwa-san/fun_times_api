group :default do
  gem "pg" # PostgreSQL
  gem "graphql" # GraphQL API
  gem "sidekiq" # Background jobs
  gem "rack-cors" # CORS support
end

group :development, :test do
  gem "rubocop", require: false # Code style checker
  gem "rubocop-rails", require: false # Rails-specific RuboCop rules
  gem "brakeman", require: false # Security scanner
  gem "bundler-audit", require: false # Dependency security checker
end

group :authentication do
  gem "devise" # User authentication
  gem "jwt" # JSON Web Token support
  gem "omniauth-auth0" # Auth0 integration
end
