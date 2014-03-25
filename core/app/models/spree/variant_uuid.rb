module Spree
  class VariantUuid < ActiveRecord::Base
    before_validation :generate_number, on: :create
    NUMBER_PREFIX = "I"
    
    after_initialize do
      self.recipe.symbolize_keys! if self.recipe
    end
    
    class << self
      def fetch(variant, option_with_qty=[], personalisations=[])
        recipe = build_hash(variant, option_with_qty, personalisations)

        recipe_sha1 = Digest::SHA1.hexdigest(recipe.to_json)

        variant_uuid = where(recipe_sha1: recipe_sha1).first
        unless variant_uuid
          serialization = recipe.reduce({}) {|hsh, i| hsh[i[0]] = i[1].to_json; hsh} 
          variant_uuid = create(recipe_sha1: recipe_sha1,
                                recipe: serialization) 
        end
        variant_uuid
      end

      private
      def build_hash(variant, options, personalisations)
        {
          base_variant_id:  variant.id,
          options:          required_options(options),
          personalisations: format_personalisations(personalisations)
        }
      end
      def required_options(opts)
        opts.map do |o|
          variant, quantity, _, assembly_definition_part_id = o
          {
            part_id: assembly_definition_part_id,
            quantity: quantity,
            variant_id: variant.id
          }
        end
      end
      def format_personalisations(list)
        list ||= []
        list.map do |pers|
          {
            personalisation_id: pers[:personalisation_id],
            data: pers[:data]
          }
        end
      end

    end

    def base_variant
      @base_variant ||= Spree::Variant.find((self.recipe[:base_variant_id]||0))
    end

    def options
      @options ||= JSON.parse((self.recipe[:options]||"[]")).map do|hsh|
        part = Spree::AssemblyDefinitionPart.find(hsh['part_id']) if hsh['part_id']
        OpenStruct.new(
                        part: part,
                        variant: Spree::Variant.find(hsh['variant_id'])
                        )
      end
    end

    def personalisations
      @personalisation ||= JSON.parse((self.recipe[:personalisations]||"[]")).map do |h|
        OpenStruct.new(
                       personalisation: Spree::Personalisation.find(h['personalisation_id']),
                       data: h['data']
                       )
      end
    end

    private
    def generate_number(force: false)
      record = true
      while record
        random = "#{NUMBER_PREFIX}#{Array.new(9){rand(9)}.join}"
        record = self.class.where(number: random).first
      end
      self.number = random if self.number.blank? || force
      self.number
    end

  end
end
