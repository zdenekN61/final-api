require 'travis/testing/factories'

FactoryGirl.define do
  factory :test_step do
    description "Test step"
  end

  factory :test_case do
    description "Test case"
  end
end

