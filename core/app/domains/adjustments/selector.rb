module Adjustments
  #  Selects adjustments according to need
  class Selector
    include Enumerable

    attr_accessor :adjustments

    def initialize(adjustments)
      @adjustments = adjustments
    end

    def each
      @adjustments.each do |adjustment|
        yield adjustment
      end
    end

    def line_item
      self.class.new(@adjustments.select { |a| a.adjustable_type == "Spree::LineItem" })
    end

    def shipping_rate
      self.class.new(@adjustments.select { |a| a.adjustable_type == "Spree::ShippingRate" })
    end

    def order
      self.class.new(@adjustments.select { |a| a.adjustable_type == "Spree::Order" })
    end

    def eligible
      self.class.new(@adjustments.select(&:eligible))
    end

    def promotion
      self.class.new(@adjustments.select { |a| a.source_type == "Spree::PromotionAction" })
    end

    def tax
      self.class.new(@adjustments.select { |a| a.source_type == "Spree::TaxRate" })
    end

    def included
      self.class.new(@adjustments.select(&:included))
    end

    def additional
      self.class.new(@adjustments.reject(&:included))
    end

    def without_shipping_rate
      self.class.new(@adjustments.reject { |a| a.adjustable_type == "Spree::ShippingRate" })
    end

    def without_tax
      self.class.new(@adjustments.reject { |a| a.source_type == "Spree::TaxRate" })
    end
  end
end
