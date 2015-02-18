class Spree::AssemblyDefinition < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :variant, class_name: "Spree::Variant"
  belongs_to :assembly_product, class_name: "Spree::Product", foreign_key: "assembly_product_id", touch: true

  belongs_to :main_part, class_name: 'Spree::AssemblyDefinitionPart'
  has_many :assembly_definition_parts,  -> { order(:position) }, dependent: :delete_all, class_name: 'Spree::AssemblyDefinitionPart'
  alias_method :parts, :assembly_definition_parts

  has_many :assembly_definition_variants, through: :assembly_definition_parts

  has_many :images, -> { order(:position) }, as: :viewable, dependent: :destroy, class_name: "Spree::AssemblyDefinitionImage"

  accepts_nested_attributes_for :images
  accepts_nested_attributes_for :assembly_definition_parts

  before_create :set_assembly_product

  validate :validate_main_part
  validate :validate_part_prices

  def validate_main_part
    # if we have a assembled we need a main part
    if self.assembly_definition_parts.detect(&:assembled).present? != self.main_part_id.present?
      errors.add(:assembly_definition, "can not have assembled parts without a main part")
    end
  end

  def validate_part_prices
    bad_parts = self.assembly_definition_parts.map do |adp|
      adp.assembly_definition_variants.select do |adv|
        adv.part_prices.detect {|p| p.amount.to_f == 0 }.present?
      end
    end.flatten
    bad_parts.each do |p|
      errors.add(:bad_prices_for, "#{p.variant.options_text}")
    end
  end

  def selected_variants_out_of_stock
    Spree::AssemblyDefinitionVariant.joins(:assembly_definition_part, :variant).
      where("spree_variants.in_stock_cache='f'").
      where("spree_assembly_definition_parts.assembly_definition_id = ?", self.id).inject({}) do |hash,adv|
        hash[adv.assembly_definition_part_id] ||= []
        hash[adv.assembly_definition_part_id] << adv.variant_id
        hash
      end
  end

  def selected_variants_out_of_stock_option_values
    Spree::AssemblyDefinitionVariant.joins(:assembly_definition_part, :variant).
      includes(variant: [:option_values]).
      where("spree_variants.in_stock_cache='f'").
      where("spree_assembly_definition_parts.assembly_definition_id = ?", self.id).inject({}) do |hash,adv|
        hash[adv.assembly_definition_part_id] ||= []
        hash[adv.assembly_definition_part_id] << adv.variant.option_values.map(&:id)
        hash
      end
  end

  def images_for(target)
    images.with_target(target)
  end

  private

  def set_assembly_product
    self.assembly_product = self.variant.product
  end

end
