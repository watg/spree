FactoryGirl.define do
  factory :personalisation, class: Spree::Personalisation do
    product { |p| p.association(:base_product) }

    factory :personalisation_monogram, class: Spree::Personalisation::Monogram do

      data {{ 
        'max_initials' => 2,
        'colours' => [ create(:option_value_colour_red).id ].join(',')
      }}

    end

  end

end
