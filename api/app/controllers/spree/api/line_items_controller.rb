module Spree
  module Api
    class LineItemsController < Spree::Api::BaseController
      class_attribute :line_item_options

      self.line_item_options = []

      def create
        variant = Spree::Variant.find(params[:line_item][:variant_id])
        options = parse_options( variant, params[:line_item][:options] || {} )

        @line_item = LineItemCreateService.run!(
          order:    order,
          variant:  variant,
          quantity: params[:line_item][:quantity],
          options:  options,
        )

        if @line_item.errors.empty?
          respond_with(@line_item, status: 201, default_template: :show)
        else
          invalid_resource!(@line_item)
        end
      end

      def update
        @line_item = find_line_item
        if @order.contents.update_cart(line_items_attributes)
          @line_item.reload
          respond_with(@line_item, default_template: :show)
        else
          invalid_resource!(@line_item)
        end
      end

      def destroy
        @line_item = find_line_item
        @order.contents.remove_by_line_item(@line_item, @line_item.quantity, {})
        respond_with(@line_item, status: 204)
      end

      private

      def order
        @order ||= Spree::Order.includes(:line_items).find_by!(number: order_id)
        authorize! :update, @order, order_token
      end

      def find_line_item
        id = params[:id].to_i
        order.line_items.detect { |line_item| line_item.id == id } or
          raise ActiveRecord::RecordNotFound
      end

      def line_items_attributes
        {line_items_attributes: {
          id: params[:id],
          quantity: params[:line_item][:quantity],
          options: line_item_params[:options] || {}
        }}
      end

      def line_item_params
        params.require(:line_item).permit(
          :quantity,
          :variant_id,
          options: line_item_options
        )
      end

      def parse_options(variant, options)
        # Below is a hack to deal with old kits as well as new
        variants = []
        if selected_variants = options.delete(:parts)
          line_item_parts = options_parser.dynamic_kit_parts(variant, selected_variants)
        else
          line_item_parts = options_parser.static_kit_required_parts(variant)
        end
        options.merge!(parts: line_item_parts)
      end

      def options_parser
        @options_parser ||= Spree::LineItemOptionsParser.new(order.currency)
      end
    end
  end
end
