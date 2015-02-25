require 'ostruct'

module Spree
  class Shipment < Spree::Base
    belongs_to :address, class_name: 'Spree::Address', inverse_of: :shipments
    belongs_to :order, class_name: 'Spree::Order', touch: true, inverse_of: :shipments
    belongs_to :stock_location, class_name: 'Spree::StockLocation'

    has_many :adjustments, as: :adjustable, dependent: :delete_all
    has_many :inventory_units, dependent: :delete_all, inverse_of: :shipment
    has_many :shipping_rates, -> { order('cost ASC') }, dependent: :delete_all
    has_many :shipping_methods, through: :shipping_rates
    has_many :state_changes, as: :stateful

    after_save :update_adjustments

    before_validation :set_cost_zero_when_nil

    attr_accessor :special_instructions

    accepts_nested_attributes_for :address
    accepts_nested_attributes_for :inventory_units

    make_permalink field: :number, length: 11, prefix: 'H'

    scope :pending, -> { with_state('pending') }
    scope :ready,   -> { with_state('ready') }
    scope :shipped, -> { with_state('shipped') }
    scope :trackable, -> { where("tracking IS NOT NULL AND tracking != ''") }
    scope :with_state, ->(*s) { where(state: s) }
    # sort by most recent shipped_at, falling back to created_at. add "id desc" to make specs that involve this scope more deterministic.
    scope :reverse_chronological, -> { order('coalesce(spree_shipments.shipped_at, spree_shipments.created_at) desc', id: :desc) }

    # shipment state machine (see http://github.com/pluginaweek/state_machine/tree/master for details)
    state_machine initial: :pending, use_transactions: false do
      event :ready do
        transition from: :pending, to: :ready, if: lambda { |shipment|
          # Fix for #2040
          shipment.determine_state(shipment.order) == 'ready'
        }
      end
      after_transition to: :ready, do: :check_for_only_digital_and_ship

      event :pend do
        transition from: :ready, to: :pending
      end

      event :ship do
        transition from: [:ready, :canceled], to: :shipped
      end
      # This was refactored due to the way we unstock an restock
      #after_transition to: :shipped, do: :after_ship
      after_transition from: :ready, to: :shipped, do: :after_ship
      after_transition from: :canceled, to: :shipped, do: [:after_resume, :after_ship]

      event :cancel do
        transition to: :canceled, from: [:pending, :ready, :awaiting_feed]
      end
      after_transition to: :canceled, do: :after_cancel

      event :resume do
        # This doesn't work.
        #
        # * Note that the first two 'if' blocks check the same thing.
        # * determine_state returns a string and not a symbol
        # * this gets overridden anyway by the final transition
        #
        # If this was fixed it would also need to handle 'awaiting_feed'
        transition from: :canceled, to: :ready, if: lambda { |shipment|
          shipment.determine_state(shipment.order) == :ready
        }
        transition from: :canceled, to: :pending, if: lambda { |shipment|
          shipment.determine_state(shipment.order) == :ready
        }
        transition from: :canceled, to: :pending
        transition from: :pending, to: :pending
        transition from: :ready, to: :ready
      end
      # This was refactored due to the way we unstock an restock
      #after_transition from: :canceled, to: [:pending, :ready, canceled], do: :after_resume
      after_transition from: :canceled, to: [:pending, :ready], do: :after_resume

      after_transition do |shipment, transition|
        shipment.state_changes.create!(
          previous_state: transition.from,
          next_state:     transition.to,
          name:           'shipment',
        )
      end
    end

    def add_shipping_method(shipping_method, selected = false)
      shipping_rates.create(shipping_method: shipping_method, selected: selected, cost: cost)
    end

    def after_cancel
      manifest.each { |item| manifest_restock(item) }
    end

    def after_resume
      manifest.each { |item| manifest_unstock(item) }
    end

    def backordered?
      inventory_units.any? { |inventory_unit| inventory_unit.backordered? }
    end

    def awaiting_feed?
      inventory_units.any? { |inventory_unit| inventory_unit.awaiting_feed? }
    end

    def ready_or_pending?
      self.ready? || self.pending?
    end

    def currency
      order ? order.currency : Spree::Config[:currency]
    end

    # Determines the appropriate +state+ according to the following logic:
    #
    # pending    unless order is complete and +order.payment_state+ is +paid+
    # shipped    if already shipped (ie. does not change the state)
    # ready      all other cases
    def determine_state(order)
      return 'canceled' if order.canceled?
      return 'pending' unless order.can_ship?
      return 'pending' if inventory_units.any?(&:backordered?)
      return 'awaiting_feed' if inventory_units.any?(&:awaiting_feed?)
      return 'shipped' if state == 'shipped'
      order.paid? || Spree::Config[:auto_capture_on_dispatch] ? 'ready' : 'pending'
    end

    def discounted_cost
      cost + promo_total
    end
    alias discounted_amount discounted_cost

    def display_cost
      Spree::Money.new(cost, { currency: currency })
    end
    alias display_amount display_cost

    def display_discounted_cost
      Spree::Money.new(discounted_cost, { currency: currency })
    end

    def display_final_price
      Spree::Money.new(final_price, { currency: currency })
    end

    def display_item_cost
      Spree::Money.new(item_cost, { currency: currency })
    end

    def editable_by?(user)
      !shipped?
    end

    def final_price
      cost + adjustment_total
    end

    def final_price_with_items
      item_cost + final_price
    end

    def finalize!
      manifest.each { |item| manifest_unstock(item) }
    end

    def include?(variant)
      inventory_units_for(variant).present?
    end

    def inventory_units_for(variant)
      inventory_units.where(variant_id: variant.id)
    end

    def inventory_units_for_item(line_item, variant = nil)
      # Vanilla spree has line_item.variant.id evaled first, this does not work for when we have
      # parts
      # inventory_units.where(line_item_id: line_item.id, variant_id: line_item.variant.id || variant.id)
      inventory_units.where(line_item_id: line_item.id, variant_id: variant.id || line_item.variant.id)
    end

    def item_cost
      line_items.map(&:amount).sum
    end

    def line_items
      inventory_units.includes(:line_item).map(&:line_item).uniq.compact
    end

    ManifestItem = Struct.new(:line_item, :variant, :quantity, :states, :inventory_units)

    def manifest
      # Grouping by the ID means that we don't have to call out to the association accessor
      # This makes the grouping by faster because it results in less SQL cache hits.
      inventory_units.group_by(&:variant_id).map do |variant_id, units|
        units.group_by(&:line_item_id).map do |line_item_id, units|

          states = {}
          units.group_by(&:state).each { |state, iu| states[state] = iu.count }

          line_item = units.first.line_item
          variant = units.first.variant
          ManifestItem.new(line_item, variant, units.length, states, units)
        end
      end.flatten
    end

    def process_order_payments
      pending_payments =  order.pending_payments
                            .sort_by(&:uncaptured_amount).reverse

      # NOTE Do we really need to force orders to have pending payments on dispatch?
      if pending_payments.empty?
        raise Spree::Core::GatewayError, Spree.t(:no_pending_payments)
      else
        shipment_to_pay = final_price_with_items
        payments_amount = 0

        payments_pool = pending_payments.each_with_object([]) do |payment, pool|
          next if payments_amount >= shipment_to_pay
          payments_amount += payment.uncaptured_amount
          pool << payment
        end

        payments_pool.each do |payment|
          capturable_amount = if payment.amount >= shipment_to_pay
                                shipment_to_pay
                              else
                                payment.amount
                              end
          cents = (capturable_amount * 100).to_i
          payment.capture!(cents)
          shipment_to_pay -= capturable_amount
        end
      end
    rescue Spree::Core::GatewayError => e
      errors.add(:base, e.message)
      return !!Spree::Config[:allow_checkout_on_gateway_error]
    end

    def ready_or_pending?
      self.ready? || self.pending?
    end

    def refresh_rates
      return shipping_rates if shipped?
      return [] unless can_get_rates?

      # StockEstimator.new assigment below will replace the current shipping_method
      original_shipping_method_id = shipping_method.try(:id)

      self.shipping_rates = Stock::Estimator.new(order).shipping_rates(to_package)

      if shipping_method
        selected_rate = shipping_rates.detect { |rate|
          rate.shipping_method_id == original_shipping_method_id
        }
        self.selected_shipping_rate_id = selected_rate.id if selected_rate
      end

      shipping_rates
    end

    def selected_shipping_rate
      shipping_rates.where(selected: true).first
    end

    def selected_shipping_rate_id
      selected_shipping_rate.try(:id)
    end

    def selected_shipping_rate_id=(id)
      shipping_rates.update_all(selected: false)
      shipping_rates.update(id, selected: true)
      self.save!
    end

    def set_up_inventory(state, variant, order, line_item, supplier=nil, line_item_part=nil)
      create_params = {
        state: state,
        variant_id: variant.id,
        order_id: order.id,
        line_item_id: line_item.id,
      }
      create_params.merge!(supplier_id: supplier.id) if !supplier.nil?
      create_params.merge!(line_item_part_id: line_item_part.id) if !line_item_part.nil?
      self.inventory_units.create create_params
    end
    alias discounted_amount discounted_cost

    def shipped=(value)
      return unless value == '1' && shipped_at.nil?
      self.shipped_at = Time.now
    end

    def shipping_method
      selected_shipping_rate.try(:shipping_method) || shipping_rates.first.try(:shipping_method)
    end

    def tax_category
      selected_shipping_rate.try(:tax_rate).try(:tax_category)
    end

    # Only one of either included_tax_total or additional_tax_total is set
    # This method returns the total of the two. Saves having to check if
    # tax is included or additional.
    def tax_total
      included_tax_total + additional_tax_total
    end

    def to_package
      package = Stock::Package.new(stock_location)
      inventory_units.includes(:variant).joins(:variant).group_by(&:state).each do |state, state_inventory_units|
        package.add_multiple state_inventory_units, state.to_sym
      end
      package
    end

    def to_param
      number
    end

    def tracking_url
      @tracking_url ||= shipping_method.build_tracking_url(tracking)
    end

    def update_amounts
      if selected_shipping_rate
        self.update_columns(
          cost: selected_shipping_rate.cost,
          adjustment_total: adjustments.additional.map(&:update!).compact.sum,
          updated_at: Time.now,
        )
      end
    end

    # Update Shipment and make sure Order states follow the shipment changes
    def update_attributes_and_order(params = {})
      if self.update_attributes params
        if params.has_key? :selected_shipping_rate_id
          # Changing the selected Shipping Rate won't update the cost (for now)
          # so we persist the Shipment#cost before calculating order shipment
          # total and updating payment state (given a change in shipment cost
          # might change the Order#payment_state)
          self.update_amounts

          order.updater.update_shipment_total
          order.updater.update_payment_state

          # Update shipment state only after order total is updated because it
          # (via Order#paid?) affects the shipment state (YAY)
          self.update_columns(
            state: determine_state(order),
            updated_at: Time.now
          )

          # And then it's time to update shipment states and finally persist
          # order changes
          order.updater.update_shipment_state
          order.updater.persist_totals
        end

        true
      end
    end

    # Updates various aspects of the Shipment while bypassing any callbacks.  Note that this method takes an explicit reference to the
    # Order object.  This is necessary because the association actually has a stale (and unsaved) copy of the Order and so it will not
    # yield the correct results.
    def update!(order)
      old_state = state
      new_state = determine_state(order)
      update_columns(
        state: new_state,
        updated_at: Time.now,
      )
      after_ship if new_state == 'shipped' and old_state != 'shipped'

      check_for_only_digital_and_ship if new_state == 'ready' and old_state != 'ready'
    end

    def transfer_to_location(variant, quantity, stock_location)
      if quantity <= 0
        raise ArgumentError
      end

      transaction do
        new_shipment = order.shipments.create!(stock_location: stock_location)

        order.contents.remove(variant, quantity, {shipment: self})
        order.contents.add(variant, quantity, {shipment: new_shipment})

        refresh_rates
        save!
        new_shipment.save!
      end
    end

    def transfer_to_shipment(variant, quantity, shipment_to_transfer_to)
      quantity_already_shipment_to_transfer_to = shipment_to_transfer_to.manifest.find{|mi| mi.line_item.variant == variant}.try(:quantity) || 0
      final_quantity = quantity + quantity_already_shipment_to_transfer_to

      if (quantity <= 0 || self == shipment_to_transfer_to)
        raise ArgumentError
      end

      transaction do
        order.contents.remove(variant, quantity, {shipment: self})
        order.contents.add(variant, quantity, {shipment: shipment_to_transfer_to})

        refresh_rates
        save!
        shipment_to_transfer_to.refresh_rates
        shipment_to_transfer_to.save!
      end
    end

    private

      def after_ship
        ShipmentHandler.factory(self).perform
        # set job to send survey 10 days later
       send_survey_email
      end

      def manifest_unstock(item)
        Stock::Allocator.new(self).unstock(item.variant, item.inventory_units)
      end

      def can_get_rates?
        order.ship_address && order.ship_address.valid?
      end

      def manifest_restock(item)
        Stock::Allocator.new(self).restock(item.variant, item.inventory_units)
      end

      def manifest_unstock(item)
        Stock::Allocator.new(self).unstock(item.variant, item.inventory_units)
      end

      def recalculate_adjustments
        Spree::ItemAdjustments.new(self).update
      end

      def check_for_only_digital_and_ship
        if order.line_items.any? && order.physical_line_items.empty?
          self.ship!
        end
      end

      def send_shipped_email
        ShipmentMailer.shipped_email(self.id).deliver
      end
      handle_asynchronously :send_shipped_email, :run_at => Proc.new { Date.tomorrow.to_time }

      def send_survey_email
        EmailSurveyJob.new(self.order).delay(run_at: 10.days.from_now ).perform
      end

      EmailSurveyJob = Struct.new(:order) do
        def perform
          ShipmentMailer.survey_email(order).deliver
        end
      end

      def set_cost_zero_when_nil
        self.cost = 0 unless self.cost
      end

      def update_adjustments
        if cost_changed? && state != 'shipped'
          recalculate_adjustments
        end
      end

  end
end
