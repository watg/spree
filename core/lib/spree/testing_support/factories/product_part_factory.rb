FactoryGirl.define do
  factory :product_part, class: Spree::ProductPart do
    product factory: :product
    part    factory: :product

    before(:create) do |c|
      if c.displayable_option_type.blank?
        c.displayable_option_type = create(:option_type)
      end
    end
  end
end

