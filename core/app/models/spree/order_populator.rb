module Spree
  class OrderPopulator
    attr_accessor :order, :currency, :options_parser, :notifications
    attr_reader :params

    Item = Struct.new(:variant, :quantity, :options, :errors)

    def initialize(order, params)
      @order = order
      @params = params
      @currency = order.currency
      @options_parser = Spree::LineItemOptionsParser.new(currency)
      @notifications = []
    end

    def populate
      item = build_item
      validate_quantity(item)
      if item.errors.empty?
        validate_params
        add_to_cart(item) if notifications.empty?
      end
      item
    end

    private

    def build_item
      # Ideally this would not go into options but be set explicitly on the item
      options = {
        suite_id: params[:suite_id],
        suite_tab_id: params[:suite_tab_id],
        target_id: params[:target_id]
      }
      errors = []
      Item.new(variant, quantity, options, errors)
    end

    def validate_quantity(item)
      add_reasonable_quantity_error(item) unless quantity < 2_147_483_647 && quantity >= 1
    end

    def add_reasonable_quantity_error(item)
      item.errors << Spree.t(:please_enter_reasonable_quantity, scope: :order_populator)
    end

    def validate_params
      check_for_missing_parts(parts) if parts
      send_notifications if notifications.any?
    end

    def check_for_missing_parts(parts)
      missing_parts = options_parser.missing_parts(variant, parts)
      missing_parts_hash = missing_parts.each_with_object({}) do |missing_part, hash|
        (missing_part_id, missing_variant_id) = missing_part
        hash[missing_part_id] = missing_variant_id
      end
      return unless missing_parts_hash.any?
      notifications << "Some required parts are missing: #{missing_parts_hash.inspect}"
    end

    def send_notifications
      notifier_params = params.merge(order_id: order.id)
      Rails.logger.error(notifier_params.inspect)
      Helpers::AirbrakeNotifier.notify(notifications.to_sentence, notifier_params)
    end

    def add_to_cart(item)
      add_parts(item) if parts
      add_static_parts(item)
      add_personalisations(item) if personalisation_params
      line_item = order.contents.add(variant, quantity, item.options)
      item.errors << line_item.errors.messages.values.join(" ") if line_item.errors.any?
    end

    def add_parts(item)
      item.options[:parts] = options_parser.dynamic_kit_parts(item.variant, parts)
    end

    def add_static_parts(item)
      parts = options_parser.static_kit_required_parts(variant)
      parts += options_parser.static_kit_optional_parts(variant, optional_static_parts)
      item.options[:parts] = parts if parts.any?
    end

    # TODO: move this into a Class of it's own
    def add_personalisations(item)
      params = personalisation_params.select { |pp| pp[:enabled] }
      personalisations = params.map do |param|
        object = Spree::Personalisation.find param[:id]
        Spree::LineItemPersonalisation.new(
          personalisation_id: object.id,
          amount: object.prices[currency] || BigDecimal.new(0),
          data: object.validate(param[:data])
        )
      end
      item.options[:personalisations] = personalisations if personalisations.any?
    end


    def quantity
      @quantity ||= params[:quantity].to_i
    end

    def parts
      @parts ||= params[:options][:parts] if params[:options] && params[:options][:parts]
    end

    def variant
      @variant ||= begin
                     includes = { product_part_variants: :product_part }
                     Spree::Variant.includes(includes).find(params[:variant_id])
                   end
    end

    def personalisation_params
      @personalisation_params ||=
        begin
          key = :personalisations
          params[:options][key] if params[:options] && params[:options][key]
        end
    end

    def optional_static_parts
      @optional_static_parts ||=
        begin
          key = :optional_static_parts
          params[:options][key] if params[:options] && params[:options][key]
        end
    end
  end
end
