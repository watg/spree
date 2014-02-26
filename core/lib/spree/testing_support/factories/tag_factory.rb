FactoryGirl.define do
  factory "spree/tag", aliases: [:tag] do
    sequence(:value) {|n| "Tag #{n}" }
  end
end
