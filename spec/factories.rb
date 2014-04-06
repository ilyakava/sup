FactoryGirl.define do
  factory :member do
    name "John"
    email "John@artsymail.com"
    group_ids [1]
  end

  factory :group do
    name "Ops"
  end
end