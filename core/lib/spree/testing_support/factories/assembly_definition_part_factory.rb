FactoryGirl.define do
  factory :assembly_definition_part, class: Spree::AssemblyDefinitionPart do
    product factory: :product
    part    factory: :product
    assembly_definition_id 0
    product_id 0

    before(:create) do |c|
      if c.displayable_option_type.blank?
        c.displayable_option_type = create(:option_type)
      end
    end
  end
end

