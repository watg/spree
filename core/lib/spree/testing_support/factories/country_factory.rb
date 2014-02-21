FactoryGirl.define do
  factory :country, class: Spree::Country do
    iso_name 'UNITED KINGDOM'
    name 'United Kingdom'
    iso 'UK'
    iso3 'GBP'
    states_required false
    numcode 001
  end
end
