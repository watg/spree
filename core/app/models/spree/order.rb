require 'spree/core/validators/email'
require 'spree/order/checkout'
require  File.join(Rails.root,'vendor/spree/core/app/jobs/spree/issue_gift_card_job.rb')

module Spree
  class Order < ActiveRecord::Base
    include Checkout

    UK_EU_TAX_RATE = 0.2

    checkout_flow do
      go_to_state :address
      go_to_state :delivery
      go_to_state :payment, if: ->(order) {
        order.update_totals
        order.payment_required?
      }
      go_to_state :confirm, if: ->(order) { order.confirmation_required? }
      go_to_state :complete
      remove_transition from: :delivery, to: :confirm
    end

    token_resource

    attr_reader :coupon_code

    if Spree.user_class
      belongs_to :user, class_name: Spree.user_class.to_s
      belongs_to :created_by, class_name: Spree.user_class.to_s
    else
      belongs_to :user
      belongs_to :created_by
    end

    belongs_to :bill_address, foreign_key: :bill_address_id, class_name: 'Spree::Address'
    alias_attribute :billing_address, :bill_address

    belongs_to :ship_address, foreign_key: :ship_address_id, class_name: 'Spree::Address'
    alias_attribute :shipping_address, :ship_address

    has_many :state_changes, as: :stateful
    has_many :line_items, -> { order('created_at ASC') }, dependent: :destroy
    has_many :payments, dependent: :destroy
    has_many :return_authorizations, dependent: :destroy
    has_many :adjustments, -> { order("#{Adjustment.table_name}.created_at ASC") }, as: :adjustable, dependent: :destroy
    has_many :line_item_adjustments, through: :line_items, source: :adjustments
    has_many :all_adjustments, class_name: 'Spree::Adjustment'
    has_many :inventory_units

    has_many :shipments, dependent: :destroy, :class_name => "Shipment" do
      def states
        pluck(:state).uniq
      end
    end

    has_many :parcels

    belongs_to :invoice_print_job, class_name: "PrintJob"
    belongs_to :image_sticker_print_job, class_name: "PrintJob"

    accepts_nested_attributes_for :line_items
    accepts_nested_attributes_for :bill_address
    accepts_nested_attributes_for :ship_address
    accepts_nested_attributes_for :payments
    accepts_nested_attributes_for :shipments

    # Needs to happen before save_permalink is called
    before_validation :set_currency
    before_validation :generate_order_number, on: :create
    before_validation :clone_billing_address, if: :use_billing?
    attr_accessor :use_billing

    before_create :link_by_email
    after_create :create_tax_charge!

    validates :email, presence: true, if: :require_email
    validates :email, email: true, if: :require_email, allow_blank: true
    validate :has_available_shipment
    validate :has_available_payment

    make_permalink field: :number

    class_attribute :update_hooks
    self.update_hooks = Set.new

    class << self
      def by_number(number)
        where(number: number)
      end

      def between(start_date, end_date)
        where(created_at: start_date..end_date)
      end

      def by_customer(customer)
        joins(:user).where("#{Spree.user_class.table_name}.email" => customer)
      end

      def by_state(state)
        where(state: state)
      end

      def complete
        where.not(completed_at: nil)
      end

      def incomplete
        where(completed_at: nil)
      end

      def to_be_packed_and_shipped
        # only physical line item to be dispatched
        includes(:payments, :line_items).
          includes(:shipments).
          where('spree_orders.state'    => 'complete',
                'spree_orders.payment_state'  => 'paid',
                'spree_shipments.state' => 'ready', 
                'spree_orders.internal' => false,
                'spree_line_items.product_nature' => :physical).
                order('spree_orders.created_at DESC')
      end

      def unprinted_invoices
        to_be_packed_and_shipped.where(:batch_invoice_print_date => nil)
      end

      def unprinted_image_stickers
        to_be_packed_and_shipped.where('batch_sticker_print_date IS NULL AND batch_invoice_print_date IS NOT NULL').order(:batch_print_id)
      end

      def last_batch_id
        last = where.not(batch_print_id: nil).order("batch_print_id DESC").first
        last ? last.batch_print_id.to_i : 0
      end

      # Use this method in other gems that wish to register their own custom logic
      # that should be called after Order#update
      def register_update_hook(hook)
        self.update_hooks.add(hook)
      end
    end

    def max_dimension
      parcels_grouped_by_box.map(&:longest_edge).sort{ |a,b| b <=> a }.first
    end

    def self.complete
      where.not(completed_at: nil)
    end


    def metapack_booking_code
      li_by_product_type = line_items.map {|li| li.variant.product.product_type == 'pattern'}
      has_only_pattern = li_by_product_type.inject(true) {|res, a| res && a }
      less_than_ten =( li_by_product_type.select {|e| e }.size < 11)
      ((has_only_pattern && less_than_ten) ? 'PATTERN' : shipping_zone_name)
    end

    def shipping_zone_name
      country_id = (self.ship_address.try(:country).nil? ? nil : self.ship_address.try(:country).id)
      if country_id
        zm = Spree::ZoneMember.where(zoneable_id: country_id, zoneable_type: "Spree::Country").first
        zm.zone.name.upcase if zm
      end
    end

    def parcels_grouped_by_box
      parcels.inject([]) do |list, parcel|
        current_parcel = list.detect {|e| e.box_id == parcel.box_id}
        if current_parcel
          current_parcel.quantity += 1
        else
          current_parcel = parcel
          current_parcel.quantity = 1
          list << current_parcel
        end

        list
      end
    end

    def self.incomplete
      where(completed_at: nil)
    end

    def item_normal_total
      if @item_normal_total.blank?
        line_items.map(&:normal_amount).sum
      else
        @item_normal_total
      end
    end

    # Use this method in other gems that wish to register their own custom logic
    # that should be called after Order#update
    def self.register_update_hook(hook)
      self.update_hooks.add(hook)
    end

    # For compatiblity with Calculator::PriceSack
    def amount
      line_items.inject(0.0) { |sum, li| sum + li.amount }
    end

    def value_in_gbp
      amount
    end

    def weight
      goods_weight = line_items.inject(0.0) { |sum, li| sum + (li.variant.weight.to_f * li.quantity) }
      boxes_weight = parcels.inject(0.0)    { |sum, p| sum + p.weight.to_f }

      goods_weight + boxes_weight
    end

    def currency
      self[:currency] || Spree::Config[:currency]
    end

    def display_outstanding_balance
      Spree::Money.new(outstanding_balance, { currency: currency })
    end

    def display_item_total
      Spree::Money.new(item_total, { currency: currency })
    end

    def display_adjustment_total
      Spree::Money.new(adjustment_total, { currency: currency })
    end

    def display_tax_total
      Spree::Money.new(tax_total, { currency: currency })
    end

    def display_ship_total
      Spree::Money.new(ship_total, { currency: currency })
    end

    def display_total
      Spree::Money.new(total, { currency: currency })
    end

    def to_param
      number.to_s.to_url.upcase
    end

    def completed?
      completed_at.present? || complete?
    end

    def has_ready_made?
      tmp= line_items.map(&:variant).map {|v|
        !(v.isa_part? || v.isa_kit? || (v.product_type.to_sym == :pattern))
      }
      tmp.inject(false) {|r,a| r= r || a; r}
    end

    # Indicates whether or not the user is allowed to proceed to checkout.
    # Currently this is implemented as a check for whether or not there is at
    # least one LineItem in the Order.  Feel free to override this logic in your
    # own application if you require additional steps before allowing a checkout.
    def checkout_allowed?
      line_items.count > 0
    end

    # Is this a free order in which case the payment step should be skipped
    def payment_required?
      total.to_f > 0.0
    end

    # If true, causes the confirmation step to happen during the checkout process
    def confirmation_required?
      Spree::Config[:always_include_confirm_step] ||
        payments.valid.map(&:payment_method).compact.any?(&:payment_profiles_supported?) ||
        # Little hacky fix for #4117
        # If this wasn't here, order would transition to address state on confirm failure
        # because there would be no valid payments any more.
        state == 'confirm'
    end

    # Indicates the number of items in the order
    def item_count
      line_items.inject(0) { |sum, li| sum + li.quantity }
    end

    def backordered?
      shipments.any?(&:backordered?)
    end

    # Returns the relevant zone (if any) to be used for taxation purposes.
    # Uses default tax zone unless there is a specific match
    def tax_zone
      Zone.match(tax_address) || Zone.default_tax
    end

    # Indicates whether tax should be backed out of the price calcualtions in
    # cases where prices include tax but the customer is not required to pay
    # taxes in that case.
    def exclude_tax?
      return false unless Spree::Config[:prices_inc_tax]
      return tax_zone != Zone.default_tax
    end

    # Returns the address for taxation based on configuration
    def tax_address
      Spree::Config[:tax_using_ship_address] ? ship_address : bill_address
    end

    # Array of totals grouped by Adjustment#label. Useful for displaying line item
    # adjustments on an invoice. For example, you can display tax breakout for
    # cases where tax is included in price.
    def line_item_adjustment_totals
      Hash[self.line_item_adjustments.eligible.group_by(&:label).map do |label, adjustments|
        total = adjustments.sum(&:amount)
        [label, Spree::Money.new(total, { currency: currency })]
      end]
    end

    def updater
      @updater ||= OrderUpdater.new(self)
    end

    def update!
      updater.update
    end

    def update_totals
      updater.update_totals
    end

    def clone_billing_address
      if bill_address and self.ship_address.nil?
        self.ship_address = bill_address.clone
      else
        self.ship_address.attributes = bill_address.attributes.except('id', 'updated_at', 'created_at')
      end
      true
    end

    def allow_cancel?
      return false unless completed? and state != 'canceled'
      shipment_state.nil? || %w{ready backorder pending}.include?(shipment_state)
    end

    def awaiting_returns?
      return_authorizations.any? { |return_authorization| return_authorization.authorized? }
    end

    def contents
      @contents ||= Spree::OrderContents.new(self)
    end

    # Associates the specified user with the order.
    def associate_user!(user)
      self.user = user
      self.email = user.email
      self.created_by = user if self.created_by.blank?

      if persisted?
        # immediately persist the changes we just made, but don't use save since we might have an invalid address associated
        self.class.unscoped.where(id: id).update_all(email: user.email, user_id: user.id, created_by_id: self.created_by_id)
      end
    end

    # FIXME refactor this method and implement validation using validates_* utilities
    def generate_order_number
      record = true
      while record
        random = "R#{Array.new(9){rand(9)}.join}"
        record = self.class.where(number: random).first
      end
      self.number = random if self.number.blank?
      self.number
    end

    def shipped_shipments
      shipments.shipped
    end

    def contains?(variant)
      find_line_item_by_variant(variant).present?
    end

    def quantity_of(variant)
      line_item = find_line_item_by_variant(variant)
      line_item ? line_item.quantity : 0
    end

    def find_line_item_by_variant(variant)
      line_items.detect { |line_item| line_item.variant_id == variant.id }
    end

    def ship_total
      adjustments.shipping.sum(:amount)
    end

    # Creates new tax charges if there are any applicable rates. If prices already
    # include taxes then price adjustments are created instead.
    def create_tax_charge!
      Spree::TaxRate.adjust(self)
    end

    def outstanding_balance
      total - payment_total
    end

    def outstanding_balance?
      self.outstanding_balance != 0
    end

    def name
      if (address = bill_address || ship_address)
        "#{address.firstname} #{address.lastname}"
      end
    end

    def can_ship?
      self.complete? || self.resumed? || self.awaiting_return? || self.returned?
    end

    def credit_cards
      credit_card_ids = payments.from_credit_card.pluck(:source_id).uniq
      CreditCard.where(id: credit_card_ids)
    end

    # Finalizes an in progress order after checkout is complete.
    # Called after transition to complete state when payments will have been processed
    def finalize!
      touch :completed_at

      # lock all adjustments (coupon promotions, etc.)
      adjustments.update_all state: 'closed'

      # update payment and shipment(s) states, and save
      updater.update_payment_state
      shipments.each do |shipment|
        shipment.update!(self)
        shipment.finalize!
      end

      updater.update_shipment_state
      save
      updater.run_hooks

      deliver_order_confirmation_email
      deliver_gift_card_emails
    end

    def deliver_gift_card_emails
      self.gift_card_line_items.each do |item|
        item.quantity.times {|position| 
          job = Spree::IssueGiftCardJob.new(self, item, position)
          ::Delayed::Job.enqueue job, :queue => 'gift_card'
        }
      end
    end

    def tax
      if %w(UK EU).include?(shipping_zone_name)
        total * UK_EU_TAX_RATE
      else
        0
      end
    end

    def has_gift_card?
      gift_card_line_items.any?
    end

    def gift_card_line_items
      self.line_items.
        includes(:variant, :product).
        where("spree_products.product_type" => :gift_card).
        reorder('spree_line_items.created_at ASC').
        references(:variant, :product)
    end

    def line_items_without_gift_cards
      (line_items - gift_card_line_items)
    end

    def item_total_without_gift_cards
      line_items_without_gift_cards.sum(&:amount)
    end

    def deliver_order_confirmation_email
      begin
        OrderMailer.confirm_email(self.id).deliver
      rescue Exception => e
        logger.error("#{e.class.name}: #{e.message}")
        logger.error(e.backtrace * "\n")
      end
    end

    # Helper methods for checkout steps
    def paid?
      payment_state == 'paid' || payment_state == 'credit_owed'
    end

    def available_payment_methods
      @available_payment_methods ||= (PaymentMethod.available(:front_end) + PaymentMethod.available(:both)).uniq
    end

    def pending_payments
      payments.select(&:checkout?)
    end

    # processes any pending payments and must return a boolean as it's
    # return value is used by the checkout state_machine to determine
    # success or failure of the 'complete' event for the order
    #
    # Returns:
    # - true if all pending_payments processed successfully
    # - true if a payment failed, ie. raised a GatewayError
    #   which gets rescued and converted to TRUE when
    #   :allow_checkout_gateway_error is set to true
    # - false if a payment failed, ie. raised a GatewayError
    #   which gets rescued and converted to FALSE when
    #   :allow_checkout_on_gateway_error is set to false
    #
    def process_payments!
      if pending_payments.empty?
        raise Core::GatewayError.new Spree.t(:no_pending_payments)
      else
        pending_payments.each do |payment|
          break if payment_total >= total

          payment.process!

          if payment.completed?
            self.payment_total += payment.amount
          end
        end
      end
    rescue Core::GatewayError => e
      result = !!Spree::Config[:allow_checkout_on_gateway_error]
      errors.add(:base, e.message) and return result
    end

    def billing_firstname
      bill_address.try(:firstname)
    end

    def billing_lastname
      bill_address.try(:lastname)
    end

    def products
      line_items.map(&:product)
    end

    def product_groups
      line_items.map(&:product).map(&:product_group)
    end

    def variants
      line_items.map(&:variant)
    end

    def insufficient_stock_lines
      line_items.select &:insufficient_stock?
    end

    def merge!(order, user = nil)
      order.line_items.each do |line_item|
        next unless line_item.currency == currency
        current_line_item = self.line_items.find_by(variant: line_item.variant)
        if current_line_item
          current_line_item.quantity += line_item.quantity
          current_line_item.save
        else
          line_item.order_id = self.id
          line_item.save
        end
      end

      self.associate_user!(user) if !self.user && !user.blank?

      # So that the destroy doesn't take out line items which may have been re-assigned
      order.line_items.reload
      order.destroy
    end

    def empty!
      adjustments.destroy_all
      line_items.destroy_all
    end

    def clear_adjustments!
      self.adjustments.destroy_all
      self.line_item_adjustments.destroy_all
    end

    def has_step?(step)
      checkout_steps.include?(step)
    end

    def state_changed(name)
      state = "#{name}_state"
      if persisted?
        old_state = self.send("#{state}_was")
        new_state = self.send(state)
        unless old_state == new_state
          self.state_changes.create(
            previous_state: old_state,
            next_state:     new_state,
            name:           name,
            user_id:        self.user_id
          )
        end
      end
    end

    def coupon_code=(code)
      @coupon_code = code.strip.downcase rescue nil
    end

    # Tells us if there if the specified promotion is already associated with the order
    # regardless of whether or not its currently eligible. Useful because generally
    # you would only want a promotion action to apply to order no more than once.
    #
    # Receives an adjustment +originator+ (here a PromotionAction object) and tells
    # if the order has adjustments from that already
    def promotion_credit_exists?(originator)
      !! adjustments.includes(:originator).promotion.reload.detect { |credit| credit.originator.id == originator.id }
    end

    def promo_total
      adjustments.eligible.promotion.sum(:amount)
    end

    def manual_adjustment_total
      adjustments.eligible.manual.sum(:amount)
    end

    def discount_total
      promo_total + manual_adjustment_total
    end

    def shipped?
      %w(partial shipped).include?(shipment_state)
    end

    def create_proposed_shipments
      adjustments.shipping.delete_all
      shipments.destroy_all

      packages = Spree::Stock::Coordinator.new(self).packages
      packages.each do |package|
        shipments << package.to_shipment
      end

      shipments
    end

    # Clean shipments and make order back to address state
    #
    # At some point the might need to force the order to transition from address
    # to delivery again so that proper updated shipments are created.
    # e.g. customer goes back from payment step and changes order items
    def ensure_updated_shipments
      if shipments.any?
        self.shipments.destroy_all
        restart_checkout_flow
      end
    end

    def restart_checkout_flow
      self.update_column(:state, checkout_steps.first)
    end

    def refresh_shipment_rates
      shipments.map &:refresh_rates
    end

    def shipping_eq_billing_address?
      (bill_address.empty? && ship_address.empty?) || bill_address.same_as?(ship_address)
    end

    def can_attempt_payment?
      payments.select(&:pending?).blank?
    end

    def is_risky?
      self.payments.where(%{
        (avs_response IS NOT NULL and avs_response != 'D') or
        (cvv_response_code IS NOT NULL and cvv_response_code != 'M') or
        cvv_response_message IS NOT NULL or
        state = 'failed'
                          }.squish!).uniq.count > 0
    end

    def find_existing_line_item(variant, target_id, options_with_qty, personalisations)
      uuid = LineItem.generate_uuid( variant, options_with_qty, personalisations )
      self.line_items.find_by(variant_id: variant.id, item_uuid: uuid, target_id: target_id)
    end

    private

    def link_by_email
      self.email = user.email if self.user
    end

    # Determine if email is required (we don't want validation errors before we hit the checkout)
    def require_email
      return true unless new_record? or ['cart', 'address'].include?(state)
    end

    def ensure_line_items_present
      unless line_items.present?
        errors.add(:base, Spree.t(:there_are_no_items_for_this_order)) and return false
      end
    end

    def has_available_shipment
      return unless has_step?("delivery")
      return unless address?
      return unless ship_address && ship_address.valid?
      # errors.add(:base, :no_shipping_methods_available) if available_shipping_methods.empty?
    end

    def ensure_available_shipping_rates
      if shipments.empty? || shipments.any? { |shipment| shipment.shipping_rates.blank? }
        errors.add(:base, Spree.t(:items_cannot_be_shipped)) and return false
      end
    end

    def has_available_payment
      return unless delivery?
      # errors.add(:base, :no_payment_methods_available) if available_payment_methods.empty?
    end

    def after_cancel
      shipments.each { |shipment| shipment.cancel! }
      payments.completed.each { |payment| payment.credit! }

      send_cancel_email
      self.update_column(:payment_state, 'credit_owed') unless shipped?
    end

    def send_cancel_email
      OrderMailer.cancel_email(self.id).deliver
    end

    def after_resume
      shipments.each { |shipment| shipment.resume! }
    end

    def use_billing?
      @use_billing == true || @use_billing == 'true' || @use_billing == '1'
    end

    def set_currency
      self.currency = Spree::Config[:currency] if self[:currency].nil?
    end
  end
end
