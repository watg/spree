module Spree
  class VariantUuid < ActiveRecord::Base
    before_validation :generate_number, on: :create
    NUMBER_PREFIX = "I"
    
    after_initialize do
      self.recipe.symbolize_keys! if self.recipe.kind_of? Hash
    end
    
    class << self
      def fetch(variant, parts=nil, personalisations=nil )
        parts ||= []
        personalisations ||= []
        recipe = build_hash(variant, parts, personalisations)

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

      def build_hash(variant, parts, personalisations)
        {
          base_variant_id:  variant.id.to_i,
          parts:            format_parts(parts),
          personalisations: format_personalisations(personalisations)
        }
      end

      def format_parts(parts)
        parts.map do |p|
          {
            part_id: p.assembly_definition_part_id.to_i,
            quantity: p.quantity.to_i,
            variant_id: p.variant_id.to_i
          }
        end
      end

      def format_personalisations(personalisations)
        personalisations.map do |p|
          {
            personalisation_id: p.personalisation_id.to_i,
            data: p.data 
          }
        end
      end
    end

    def base_variant
      @base_variant ||= Spree::Variant.find((self.recipe[:base_variant_id]||0))
    end

    def parts
      @parts ||= JSON.parse((self.recipe[:parts]||"[]")).map do|hsh|
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
