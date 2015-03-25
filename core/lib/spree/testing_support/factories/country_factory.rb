FactoryGirl.define do
  factory :country, class: Spree::Country do
    iso_name 'UNITED STATES'
    name 'United States of America'
    iso 'US'
    iso3 'USA'
    numcode 840
  end

  factory :country_uk, class: Spree::Country do
    iso_name 'UNITED KINGDOM'
    name 'United Kingdom'
    iso 'UK'
    iso3 'GBP'
    states_required false
    numcode 001
  end

  factory :country_canada, class: Spree::Country do
    iso_name 'CANADA'
    name 'Canada'
    iso 'CA'
    iso3 'CAN'
    states_required false
    numcode 002
  end
end
