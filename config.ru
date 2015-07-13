$: << 'lib'
require 'bundler/setup'

require 'final-api/app'

FinalAPI.setup
run FinalAPI::App
