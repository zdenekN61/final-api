# A sample Gemfile
source "https://rubygems.org"

ruby '2.2.2'

gem 'travis-core',        github: 'final-ci/travis-core'
#gem 'travis-core',        path: '../travis-core'
gem 'travis-config',      '~> 0.1.0'
gem 'travis-support',     github: 'final-ci/travis-support'
gem 'pg'

gem 'micro_migrations'
gem 'travis-sidekiqs',    github: 'final-ci/travis-sidekiqs', require: nil
gem 'sidekiq-status',     github: 'utgarda/sidekiq-status', ref: 'e77d5dc2ea0a249ccbbafead21ece59d6b8caf73'


gem 'connection_pool'

gem 'rack'
gem 'rack-contrib'
gem 'sinatra', '~> 1.4.6', require: 'sinatra/base' #see https://github.com/resque/resque/issues/934
gem 'sinatra-contrib', '~> 1.4.4'

gem 'sentry-raven'#,    github: 'getsentry/raven-ruby'
gem 'metriks'

gem 'bunny'

gem 'metriks-librato_metrics'

gem 'unicorn'


group :test do
  gem 'rspec'
  gem 'factory_girl',     '~> 2.6.0'
  gem 'database_cleaner', '~> 1.4.1'
  gem "fakefs",           require: nil
end

group 'development' do
  gem 'rerun'
end

gem 'stash-client'

# gem "rails"
