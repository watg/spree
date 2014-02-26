FactoryGirl.define do
  factory :image, class: Spree::Image do
    association :viewable, factory: :base_variant
    alt "alt text"
    attachment File.open(File.expand_path('../../fixtures/thinking-cat.jpg', __FILE__))
  end
end
