module Spree
  module Jobs
    # TODO -put scope on assembly definition parts
    # pass in variant

    AddVariantToAssemblyPart ||= Struct.new(:variant) do

      def perform
        variant.product.part_products.each do |part_product|
          if part_product.add_all_available_variants == true
            part_product.assembly_definition_variants.find_or_create_by(variant_id: variant.id)
          end
        end
      end

    end
  end
end
