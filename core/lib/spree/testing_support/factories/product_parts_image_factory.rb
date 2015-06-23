FactoryGirl.define do
  factory :product_parts_image, class: Spree::ProductPartsImage do
    alt "alt text"
    attachment File.open(File.expand_path('../../fixtures/thinking-cat.jpg', __FILE__))
  end
end
