FactoryGirl.define do
  factory :line_item_personalisation, class: Spree::LineItemPersonalisation do
    personalisation { build(:personalisation_monogram) }
    data { { 'colour' =>  personalisation.colours.first.id, 'initials' => 'DD' } }
    line_item
  end
end
