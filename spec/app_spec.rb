require 'spec_helper'
require 'final-api/app'

describe FinalAPI::App do
  include Rack::Test::Methods

  def app
    FinalAPI::App.new
  end
  #it "should create test case when first" do
  #  expect {
  #    post '/testCaseResults'
  #  }.to change {TestCase.count}.by 1
  # end

  # it "should not create test case " do

  #it "GET /tests/:id" do
  #  response = get '/tests'
  #  expect(response.status).to eq 200
  #  expect(JSON.parse(response)).to match_response_schema("tests")
  #end
end
