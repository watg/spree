FactoryGirl.define do

  factory :option_value_colour_red, class: Spree::OptionValue do
    sequence(:name) {|e| "red#{e}"}
    presentation 'Red'
    option_type
  end

  factory :option_value, class: Spree::OptionValue do
    sequence(:name) {|e| "hot-pink#{e}"}
    option_type

    after(:build) do |i,evaluator|
      if evaluator.presentation.nil?
        if evaluator.name
          i.presentation = evaluator.name
        else
          i.presentation = 'Hot Pink'
        end
      end
    end

  end

  factory :option_type, class: Spree::OptionType do
    name 'color'
    presentation 'Color'
    sku_part 'COL'
  end

end
