FactoryGirl.define do
  factory :assembly_definition_part, class: Spree::AssemblyDefinitionPart do
    product

    before(:create) do |c|
      if c.displayable_option_type.blank?
        c.displayable_option_type = create(:option_type)
      end
    end

  end
end

