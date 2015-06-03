FactoryGirl.define do
  factory :assembly_definition_part, class: Spree::AssemblyDefinitionPart do
    part_product factory: :product
    assembly_definition_id 0

    before(:create) do |c|
      if c.displayable_option_type.blank?
        c.displayable_option_type = create(:option_type)
      end
    end
  end
end

