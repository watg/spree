FactoryGirl.define do
  factory :index_page, class: Spree::IndexPage do
    sequence(:name) {|n| "Index Page #{n}" }
    sequence(:title) {|n| "Index Page Title #{n}" }
    sequence(:permalink)  {|n| "hats-and-scarves-#{n}"}
    taxon
  end
end
