FactoryGirl.define do
  factory :suite_image, class: Spree::SuiteImage do
    alt "alt text"
    attachment File.open(File.expand_path('../../fixtures/thinking-cat.jpg', __FILE__))
  end
end
