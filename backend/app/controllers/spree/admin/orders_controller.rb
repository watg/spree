module Spree

  class OrderInvoice < ::Prawn::Document
    def to_pdf(order)

      logopath = File.join(Rails.root, 'app/assets/images/', 'logo-watg-135x99.png' )
      initial_y = cursor
      initialmove_y = 5
      address_x = 35
      invoice_header_x = 325
      lineheight_y = 12
      font_size = 9

      move_down initialmove_y

      # Add the font style and size
      font "Helvetica"
      font_size font_size

      #start with EON Media Group
      text_box "WOOL AND THE GANG SA", :at => [address_x,  cursor]
      move_down lineheight_y
      text_box "Unit C106", :at => [address_x,  cursor]
      move_down lineheight_y
      text_box "89a Shacklewell Lane", :at => [address_x,  cursor]
      move_down lineheight_y
      text_box "E8 2EB", :at => [address_x,  cursor]
      move_down lineheight_y
      text_box "London UK", :at => [address_x,  cursor]
      move_down lineheight_y
      move_down lineheight_y
      text_box "Email: info@woolandthegang.com", :at => [address_x,  cursor]

      last_measured_y = cursor
      move_cursor_to bounds.height

      image logopath, :width => 100, :position => :right

      move_cursor_to last_measured_y

      # client address
      move_down 65
      last_measured_y = cursor

      text_box "#{order.shipping_address.firstname} #{order.shipping_address.lastname} ", :at => [address_x,  cursor]
      move_down lineheight_y
      text_box order.shipping_address.address1, :at => [address_x,  cursor]
      move_down lineheight_y
      text_box order.shipping_address.address2 || '', :at => [address_x,  cursor]
      move_down lineheight_y
      text_box order.shipping_address.city, :at => [address_x,  cursor]
      move_down lineheight_y
      text_box order.shipping_address.country.name, :at => [address_x,  cursor]
      move_down lineheight_y
      text_box order.shipping_address.zipcode, :at => [address_x,  cursor]
      move_down lineheight_y
      text_box order.shipping_address.phone, :at => [address_x,  cursor]

      move_cursor_to last_measured_y

      invoice_header_data = [ 
        ["Invoice #", order.number ],
        ["Invoice Date", order.created_at.to_s(:db) ],
        ["Amount Due",   order.display_total.to_s ]
      ]


      table(invoice_header_data, :position => invoice_header_x, :width => 215) do
        style(row(0..1).columns(0..1), :padding => [1, 5, 1, 5], :borders => [])
        style(row(2), :background_color => 'e9e9e9', :border_color => 'dddddd', :font_style => :bold)
        style(column(1), :align => :right)
        style(row(2).columns(0), :borders => [:top, :left, :bottom])
        style(row(2).columns(1), :borders => [:top, :right, :bottom])
      end

      move_down 45

      invoice_services_data = [ [ 'product', 'part', 'options', 'price', 'quantity', 'total' ] ]
      order.line_items.each do |item|
        invoice_services_data << [
          item.variant.product.name,
          '-',
          item.variant.option_values.empty? ? '' : item.variant.options_text,
          item.single_money.to_s,
          item.quantity,
          item.display_amount.to_s
        ]
        if item.product.product_type == 'kit' or item.product.product_type == 'virtual_product'

          item.variant.required_parts_for_display.each do |p|
            invoice_services_data << [
              '-',
              p.name,
              p.option_values.empty? ? '' : p.options_text,
              '-',
              p.count_part,
              '-',
            ]
          end
          item.line_item_options.each do |p|
            invoice_services_data << [
              '-',
              p.variant.name,
              p.variant.option_values.empty? ? '' : p.variant.options_text,
              '-',
              p.quantity,
              '-',
            ]
          end

        end

      end

      table(invoice_services_data, :width => bounds.width) do
        style(row(1..-1).columns(0..-1), :padding => [4, 5, 4, 5], :borders => [:bottom], :border_color => 'dddddd')
        style(row(0), :background_color => 'e9e9e9', :border_color => 'dddddd', :font_style => :bold)
        style(row(0).columns(0..-1), :borders => [:top, :bottom])
        style(row(0).columns(0), :borders => [:top, :left, :bottom])
        style(row(0).columns(-1), :borders => [:top, :right, :bottom])
        style(row(-1), :border_width => 2)
        style(column(2..-1), :align => :right)
        style(columns(0), :width => 75)
        style(columns(1), :width => 75)
        style(columns(2), :width => 200)
      end

      move_down 1

      invoice_services_totals_data = [ [ "Sub Total", order.display_item_total.to_s ] ]
      order.adjustments.eligible.each do |adjustment|
      next if (adjustment.originator_type == 'Spree::TaxRate') and (adjustment.amount == 0)
         invoice_services_totals_data  << [ adjustment.label ,  adjustment.display_amount.to_s ]
      end
      invoice_services_totals_data.push [ "Order Total", order.display_total.to_s ]

      table(invoice_services_totals_data, :position => invoice_header_x, :width => 215) do
        style(row(0..1).columns(0..1), :padding => [1, 5, 1, 5], :borders => [])
        style(row(0), :font_style => :bold)
        style(row(2), :background_color => 'e9e9e9', :border_color => 'dddddd', :font_style => :bold)
        style(column(1), :align => :right)
        style(row(2).columns(0), :borders => [:top, :left, :bottom])
        style(row(2).columns(1), :borders => [:top, :right, :bottom])
      end

      move_down 25

      invoice_terms_data = [ 
        ["Delivery Terms"],
        ["Goods shipped by wool and the gang"]
      ]

      table(invoice_terms_data, :width => 275) do
        style(row(0..-1).columns(0..-1), :padding => [1, 0, 1, 0], :borders => [])
        style(row(0).columns(0), :font_style => :bold)
      end

      move_down 25

      signature_data = [ 
        ["Name", "Signature", "Date"],
        ['','' ,'' ],
      ]

      table(signature_data, :width => 350) do
        style(row(1..-1).columns(0..-1), :padding => [4, 5, 4, 5], :borders => [:bottom], :border_color => 'dddddd')
        style(row(0), :background_color => 'e9e9e9', :border_color => 'dddddd', :font_style => :bold)
        style(row(0).columns(0..-1), :borders => [:top, :bottom])
        style(row(0).columns(0), :borders => [:top, :left, :bottom])
        style(row(0).columns(-1), :borders => [:top, :right, :bottom])
        style(row(1), :border_width => 2, :height => 20 )
      end

      render
    end
  end


  module Admin
    class OrdersController < Spree::Admin::BaseController
      require 'spree/core/gateway_error'
      before_filter :initialize_order_events
      before_filter :load_order, :only => [:edit, :update, :fire, :resend, :open_adjustments, :close_adjustments]

      respond_to :html

      def index
        params[:q] ||= {}
        params[:q][:completed_at_not_null] ||= '1' if Spree::Config[:show_only_complete_orders_by_default]
        @show_only_completed = params[:q][:completed_at_not_null].present?
        params[:q][:s] ||= @show_only_completed ? 'completed_at desc' : 'created_at desc'

        # As date params are deleted if @show_only_completed, store
        # the original date so we can restore them into the params
        # after the search
        created_at_gt = params[:q][:created_at_gt]
        created_at_lt = params[:q][:created_at_lt]

        params[:q].delete(:inventory_units_shipment_id_null) if params[:q][:inventory_units_shipment_id_null] == "0"

        if !params[:q][:created_at_gt].blank?
          params[:q][:created_at_gt] = Time.zone.parse(params[:q][:created_at_gt]).beginning_of_day rescue ""
        end

        if !params[:q][:created_at_lt].blank?
          params[:q][:created_at_lt] = Time.zone.parse(params[:q][:created_at_lt]).end_of_day rescue ""
        end

        if @show_only_completed
          params[:q][:completed_at_gt] = params[:q].delete(:created_at_gt)
          params[:q][:completed_at_lt] = params[:q].delete(:created_at_lt)
        end

        @search = Order.accessible_by(current_ability, :index).ransack(params[:q])
        @orders = @search.result.includes([:user, :shipments, :payments]).
          page(params[:page]).
          per(params[:per_page] || Spree::Config[:orders_per_page])

        # Restore dates
        params[:q][:created_at_gt] = created_at_gt
        params[:q][:created_at_lt] = created_at_lt
      end

      def new
        @order = Order.create
        redirect_to edit_admin_order_url(@order)
      end

      def edit
        @order.shipments.map &:refresh_rates
      end

      def show
        @order = Order.find_by_number!(params[:id])
        invoice = Spree::OrderInvoice.new.to_pdf(@order)
        respond_to do |format|
          format.pdf do
            send_data invoice, :filename => "hello.pdf", 
              :type => "application/pdf"
          end
        end
      end

      def update
        return_path = nil
        if @order.update_attributes(params[:order]) && @order.line_items.present?
          @order.update!
          unless @order.complete?
            # Jump to next step if order is not complete.
            return_path = admin_order_customer_path(@order)
          else
            # Otherwise, go back to first page since all necessary information has been filled out.
            return_path = admin_order_path(@order)
          end
        else
          @order.errors.add(:line_items, Spree.t('errors.messages.blank')) if @order.line_items.empty?
        end

        if return_path
          redirect_to return_path
        else
          render :action => :edit
        end
      end

      def fire
        # TODO - possible security check here but right now any admin can before any transition (and the state machine
        # itself will make sure transitions are not applied in the wrong state)
        event = params[:e]
        if @order.send("#{event}")
          flash[:success] = Spree.t(:order_updated)
        else
          flash[:error] = Spree.t(:cannot_perform_operation)
        end
      rescue Spree::Core::GatewayError => ge
        flash[:error] = "#{ge.message}"
      ensure
        redirect_to :back
      end

      def resend
        OrderMailer.confirm_email(@order.id, true).deliver
        flash[:success] = Spree.t(:order_email_resent)

        redirect_to :back
      end

      def open_adjustments
        adjustments = @order.adjustments.where(:state => 'closed')
        adjustments.update_all(:state => 'open')
        flash[:success] = Spree.t(:all_adjustments_opened)

        respond_with(@order) { |format| format.html { redirect_to :back } }
      end

      def close_adjustments
        adjustments = @order.adjustments.where(:state => 'open')
        adjustments.update_all(:state => 'closed')
        flash[:success] = Spree.t(:all_adjustments_closed)

        respond_with(@order) { |format| format.html { redirect_to :back } }
      end

      private

        def load_order
          @order = Order.find_by_number!(params[:id], :include => :adjustments) if params[:id]
          authorize! action, @order
        end

        # Used for extensions which need to provide their own custom event links on the order details view.
        def initialize_order_events
          @order_events = %w{cancel resume}
        end

        def model_class
          Spree::Order
        end
    end
  end
end

