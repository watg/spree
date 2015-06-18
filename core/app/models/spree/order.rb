require 'spree/core/validators/email'
require 'spree/order/checkout'

module Spree
  class Order < Spree::Base

    ORDER_NUMBER_LENGTH  = 9
    ORDER_NUMBER_LETTERS = false
    ORDER_NUMBER_PREFIX  = 'R'

    include Spree::Order::Checkout
    include Spree::Order::CurrencyUpdater
    include Spree::Order::Payments

    checkout_flow do
      go_to_state :address
      go_to_state :delivery
      go_to_state :payment, if: ->(order) { order.payment_required? }
      go_to_state :confirm, if: ->(order) { order.confirmation_required? }
      go_to_state :complete
      remove_transition from: :delivery, to: :confirm
    end

    attr_reader :coupon_code
    attr_accessor :temporary_address, :temporary_credit_card

    if Spree.user_class
      belongs_to :user, class_name: Spree.user_class.to_s
      belongs_to :created_by, class_name: Spree.user_class.to_s
      belongs_to :approver, class_name: Spree.user_class.to_s
      belongs_to :canceler, class_name: Spree.user_class.to_s
    else
      belongs_to :user
      belongs_to :created_by
      belongs_to :approver
      belongs_to :canceler
    end

    belongs_to :bill_address, foreign_key: :bill_address_id, class_name: 'Spree::Address'
    alias_attribute :billing_address, :bill_address

    belongs_to :ship_address, foreign_key: :ship_address_id, class_name: 'Spree::Address'
    alias_attribute :shipping_address, :ship_address

    alias_attribute :ship_total, :shipment_total

    has_many :state_changes, as: :stateful
    has_many :line_items, -> { order("#{LineItem.table_name}.created_at ASC") }, dependent: :destroy, inverse_of: :order
    has_many :payments, dependent: :destroy
    has_many :return_authorizations, dependent: :destroy, inverse_of: :order
    has_many :reimbursements, inverse_of: :order
    has_many :adjustments, -> { order("#{Adjustment.table_name}.created_at ASC") }, as: :adjustable, dependent: :destroy
    has_many :line_item_adjustments, through: :line_items, source: :adjustments
    has_many :shipping_rates, through: :shipments
    has_many :shipping_rate_adjustments, through: :shipping_rates, source: :adjustments
    has_many :inventory_units, inverse_of: :order
    has_many :products, through: :variants
    has_many :variants, through: :line_items
    has_many :refunds, through: :payments
    has_many :suites, through: :line_items

    has_and_belongs_to_many :promotions, join_table: 'spree_orders_promotions'

    has_many :shipments, dependent: :destroy, inverse_of: :order do
      def states
        pluck(:state).uniq
      end
    end

    has_many :parcels
    has_many :line_item_parts, through: :line_items

    has_many :order_notes

    belongs_to :invoice_print_job, class_name: "PrintJob"
    belongs_to :image_sticker_print_job, class_name: "PrintJob"
    belongs_to :order_type, class_name: "OrderType"

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


    before_create :create_token
    before_create :link_by_email
    before_update :homogenize_line_item_currencies, if: :currency_changed?

    validates :email, presence: true, if: :require_email
    validates :email, email: true, if: :require_email, allow_blank: true
    validates :number, presence: true, uniqueness: { allow_blank: true }
    validate :has_available_shipment

    make_permalink field: :number

    delegate :update_totals, :persist_totals, :to => :updater

    class_attribute :update_hooks
    self.update_hooks = Set.new

    SHIPPABLE_STATES = %w(complete resumed awaiting_return returned)
    STOCK_ALLOCATABLE_STATES = SHIPPABLE_STATES + %w(warehouse_on_hold customer_service_on_hold)

    class_attribute :line_item_comparison_hooks
    self.line_item_comparison_hooks = Set.new


    scope :created_between, ->(start_date, end_date) { where(created_at: start_date..end_date) }
    scope :completed_between, ->(start_date, end_date) { where(completed_at: start_date..end_date) }
    scope :in_currency, ->(currency) { where(currency: currency) }

    # shows completed orders first, by their completed_at date, then uncompleted orders by their created_at
    scope :reverse_chronological, -> { order('spree_orders.completed_at IS NULL', completed_at: :desc, created_at: :desc) }

    class << self
      def by_number(number)
        where(number: number)
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

      def not_cancelled
        where.not(state: :canceled)
      end

      def shippable_state
        where(state: SHIPPABLE_STATES)
      end

      def prioritised
        # We use COALESCE to turn nulls into falses
        order("COALESCE(spree_orders.important, FALSE) DESC, spree_orders.completed_at DESC")
      end

      # only physical line item to be dispatched
      def to_be_packed_and_shipped
        non_digital_product_type_ids = Spree::ProductType.where(is_digital: false).pluck(:id)
        select('spree_orders.*', "COALESCE(spree_orders.important, FALSE)").includes(line_items: [variant: :product]).
        shippable_state.
        where(payment_state: 'paid',
              shipment_state: 'ready',
              internal: false,
              'spree_products.product_type_id' => non_digital_product_type_ids).
        prioritised
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

    def run_post_payment_tasks
      OrderPostPaymentNotifier.new(self).process
    end

    def max_dimension
      parcels_grouped_by_box.map(&:longest_edge).sort{ |a,b| b <=> a }.first
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




    # Use this method in other gems that wish to register their own custom logic
    # that should be called after Order#update
    def self.register_update_hook(hook)
      self.update_hooks.add(hook)
    end

    # Use this method in other gems that wish to register their own custom logic
    # that should be called when determining if two line items are equal.
    def self.register_line_item_comparison_hook(hook)
      self.line_item_comparison_hooks.add(hook)
    end

    register_line_item_comparison_hook :item_uuid_match

    def item_uuid_match(line_item, options)
      opts = options.symbolize_keys
      line_item.item_uuid == opts[:item_uuid]
    end

    def all_adjustments
      Adjustment.where("order_id = :order_id OR (adjustable_id = :order_id AND adjustable_type = 'Spree::Order')",
                       order_id: self.id)
    end

    # For compatiblity with Calculator::PriceSack
    def amount
      line_items.inject(0.0) { |sum, li| sum + li.amount }
    end

    def value_in_gbp
      amount
    end

    def weight
      goods_weight = line_items.inject(0.0) { |sum, li| sum + li.weight.to_f }
      boxes_weight = parcels.inject(0.0)    { |sum, p| sum + p.weight.to_f }

      goods_weight + boxes_weight
    end

    def cost_price_total
      line_items.inject(0.0) { |sum, li| sum + li.cost_price.to_f }
    end

    # Sum of all line item amounts pre-tax
    def pre_tax_item_amount
      line_items.to_a.sum(&:pre_tax_amount)
    end
    
    def shipped_at
      shipments.first.shipped_at
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

    def display_included_tax_total
      Spree::Money.new(included_tax_total, { currency: currency })
    end

    def display_additional_tax_total
      Spree::Money.new(additional_tax_total, { currency: currency })
    end

    def display_tax_total
      Spree::Money.new(tax_total, { currency: currency })
    end

    def display_shipment_total
      Spree::Money.new(shipment_total, { currency: currency })
    end
    alias :display_ship_total :display_shipment_total

    def display_total
      Spree::Money.new(total, { currency: currency })
    end

    def to_param
      number.to_s.to_url.upcase
    end

    def completed?
      completed_at.present?
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

    def backordered?
      shipments.any?(&:backordered?)
    end

    def awaiting_feed?
      shipments.any?(&:awaiting_feed?)
    end

    # Returns the relevant zone (if any) to be used for taxation purposes.
    # Uses default tax zone unless there is a specific match
    def tax_zone
      @tax_zone ||= Zone.match(tax_address) || Zone.default_tax
    end

    # Returns the address for taxation based on configuration
    def tax_address
      Spree::Config[:tax_using_ship_address] ? ship_address : bill_address
    end

    def updater
      @updater ||= OrderUpdater.new(self)
    end

    def update!
      updater.update
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
      shipment_state.nil? || %w{ready backorder awaiting_feed pending}.include?(shipment_state)
    end
    def can_cancel?
      allow_cancel?
    end

    def all_inventory_units_returned?
      inventory_units.all? { |inventory_unit| inventory_unit.returned? }
    end

    def contents
      @contents ||= Spree::OrderContents.new(self)
    end

    # Associates the specified user with the order.
    def associate_user!(user, override_email = true)
      self.user = user
      attrs_to_set = { user_id: user.id }
      attrs_to_set[:email] = user.email if override_email
      attrs_to_set[:created_by_id] = user.id if self.created_by.blank?
      assign_attributes(attrs_to_set)

      if persisted?
        # immediately persist the changes we just made, but don't use save since we might have an invalid address associated
        self.class.unscoped.where(id: id).update_all(attrs_to_set)
      end
    end

    def generate_order_number(options = {})
      options[:length]  ||= ORDER_NUMBER_LENGTH
      options[:letters] ||= ORDER_NUMBER_LETTERS
      options[:prefix]  ||= ORDER_NUMBER_PREFIX

      possible = (0..9).to_a
      possible += ('A'..'Z').to_a if options[:letters]

      self.number ||= loop do
        # Make a random number.
        random = "#{options[:prefix]}#{(0...options[:length]).map { possible.shuffle.first }.join}"
        # Use the random  number if no other order exists with it.
        if self.class.exists?(number: random)
          # If over half of all possible options are taken add another digit.
          options[:length] += 1 if self.class.count > (10 ** options[:length] / 2)
        else
          break random
        end
      end
    end

    def shipped_shipments
      shipments.shipped
    end

    def contains?(variant, options = {})
      find_line_item_by_variant(variant, options).present?
    end

    def quantity_of(variant, options = nil)
      line_item = find_line_item_by_variant(variant, options)
      line_item ? line_item.quantity : 0
    end

    def find_line_item_by_variant(variant, options = nil)
      line_items.detect { |line_item|
        line_item.variant_id == variant.id &&
        line_item_options_match(line_item, options)
      }
    end

    # This method enables extensions to participate in the
    # "Are these line items equal" decision.
    #
    # When adding to cart, an extension would send something like:
    # params[:product_customizations]={...}
    #
    # and would provide:
    #
    # def product_customizations_match
    def line_item_options_match(line_item, options)
      return true unless options

      self.line_item_comparison_hooks.all? { |hook|
        self.send(hook, line_item, options)
      }
    end

    # Creates new tax charges if there are any applicable rates. If prices already
    # include taxes then price adjustments are created instead.
    def create_tax_charge!
      # We want to only look up the applicable tax zone once and pass it to TaxRate calculation to avoid duplicated lookups.
      Spree::TaxRate.adjust(self, line_items) if line_items.any?

      shipping_rates = shipments.map(&:shipping_rates).flatten
      Spree::TaxRate.adjust(self, shipping_rates) if shipping_rates.any?
    end

    def outstanding_balance
      if self.state == 'canceled' && self.payments.present? && self.payments.completed.size > 0
        -1 * payment_total
      else
        total - payment_total
      end
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
      SHIPPABLE_STATES.include?(self.state)
    end

    def can_allocate_stock?
      STOCK_ALLOCATABLE_STATES.include?(self.state)
    end

    def credit_cards
      credit_card_ids = payments.from_credit_card.pluck(:source_id).uniq
      CreditCard.where(id: credit_card_ids)
    end

    def valid_credit_cards
      credit_card_ids = payments.from_credit_card.valid.pluck(:source_id).uniq
      CreditCard.where(id: credit_card_ids)
    end

    # Finalizes an in progress order after checkout is complete.
    # Called after transition to complete state when payments will have been processed
    def finalize!
      # lock all adjustments (coupon promotions, etc.)
      all_adjustments.each{|a| a.close}

      # update payment and shipment(s) states, and save
      updater.update_payment_state
      shipments.each do |shipment|
        shipment.update!(self)
        shipment.finalize!
      end

      updater.update_shipment_state
      save!
      updater.run_hooks

      touch :completed_at

      unless confirmation_delivered? || internal?
        deliver_order_confirmation_email
      end

      consider_risk

      # temporary notification until we implement the Assembly State Machine
      send_notification_if_assembly_required
    end

    # temporary notification until we implement the Assembly State Machine
    def send_notification_if_assembly_required
      return unless line_items_require_assembly?
      make_order_internal
      AssemblyRequiredMailer.new(order).send
    end

    def make_order_internal
      update_column(:internal, true)
    end

    def line_items_require_assembly?
      line_items.detect { |li| li.variant.product.assemble? }
    end

    def line_items_requiring_assembly
      line_items.select { |li| li.variant.product.assemble? }
    end

    def send_assembly_required_notification
      order_url = Spree::Core::Engine.routes.url_helpers.edit_admin_order_url(self)
      products = line_items_requiring_assembly.map { |li| li.variant.product.name }.join(", ")
      message = "Hello,\n
          Order <a href='#{order_url}'>##{self.number}</a> contains customisation(s):\n
          <b>#{products}</b>.\n
          It has been marked as internal.\n
          Thank you."
      Spree::NotificationMailer.delay.send_notification(
        message,
        Rails.application.config.personalisation_email_list,
        "Customisation Order #" + self.number.to_s
      )
    end

    def has_gift_card?
      gift_card_line_items.any?
    end

    def gift_card_line_items
      self.line_items.
        includes(:variant, product: [:product_type]).
        # TODO: It would be great if this was more generic e.g. digital rather than
        # gift_card, that way we can have a generic delviery behaviour with type
        # deciding at the very end what is to be delivered
        where("spree_product_types.name" => Spree::ProductType::TYPES[:gift_card]).
        reorder('spree_line_items.created_at ASC').
        references(:variant, :product)
    end

    def physical_line_items
      self.line_items.
      includes(:variant, product: [:product_type]).
      where("spree_product_types.is_digital" => false).
      reorder('spree_line_items.created_at ASC').
      references(:variant, :product)
    end

    def line_items_without_gift_cards
      (line_items - gift_card_line_items)
    end

    def item_total_without_gift_cards
      item_total - gift_card_line_items.to_a.sum(&:amount)
    end

    def deliver_order_confirmation_email
      OrderMailer.confirm_email(self.id).deliver
      update_column(:confirmation_delivered, true)
    end

    # Helper methods for checkout steps
    def paid?
      payment_state == 'paid' || payment_state == 'credit_owed'
    end

    def available_payment_methods
      @available_payment_methods ||= (PaymentMethod.available(:front_end) + PaymentMethod.available(:both)).uniq
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

    def insufficient_stock_lines
      @insufficient_stock_lines ||= Spree::Stock::AvailabilityValidator.new.invalid_line_items(self)
    end

    def product_groups
      line_items.map(&:product).map(&:product_group)
    end

    def variants
      line_items.map(&:variant)
    end

    ##
    # Check to see if any line item variants are soft, deleted.
    # If so add error and restart checkout.
    def ensure_line_item_variants_are_not_deleted
      if line_items.select{ |li| li.variant.paranoia_destroyed? }.present?
        restart_checkout_flow
        errors.add(:base, Spree.t(:deleted_variants_present))
        self.prune_line_items!
        false
      else
        true
      end
    end

    def ensure_line_items_are_in_stock
      if insufficient_stock_lines.present?
        restart_checkout_flow
        errors.add(:base, Spree.t(:insufficient_stock_lines_present))
        self.prune_line_items!
        false
      else
        true
      end
    end

    def merge!(order, user = nil)
      order.line_items.each do |other_order_line_item|
        next unless other_order_line_item.currency == currency

        # Compare the line items of the other order with mine.
        # Make sure you allow any extensions to chime in on whether or
        # not the extension-specific parts of the line item match
        current_line_item = self.line_items.detect { |my_li|
          my_li.variant == other_order_line_item.variant &&
          self.line_item_comparison_hooks.all? { |hook|
            self.send(hook, my_li, other_order_line_item.serializable_hash)
          }
        }
        if current_line_item
          current_line_item.quantity += other_order_line_item.quantity
          if current_line_item.valid?
            current_line_item.save!
          end
        else
          if other_order_line_item.valid?
            other_order_line_item.order_id = self.id
            other_order_line_item.save!
          end
        end
      end

      self.associate_user!(user) if !self.user && !user.blank?

      updater.update_item_count
      updater.update_item_total
      updater.persist_totals

      # So that the destroy doesn't take out line items which may have been re-assigned
      order.line_items.reload
      order.destroy
    end

    def reactivate_gift_cards!
      # Another way we could achieve the same effect
      #adjustments.gift_card.map(&:source).select(&:redeemed?).each do |gift_card|
      Spree::GiftCard.redeemed.where(beneficiary_order: self).each do |gift_card|
        gift_card.reactivate
      end
    end

    def empty!
      line_items.destroy_all
      updater.update_item_count
      adjustments.destroy_all
      shipments.destroy_all

      update_totals
      persist_totals
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

    def can_add_coupon?
      Spree::Promotion.order_activatable?(self)
    end


    def shipped?
      %w(partial shipped).include?(shipment_state)
    end

    def create_proposed_shipments
      delete_all_shipping_rate_adjustments
      shipments.destroy_all
      self.shipments = Spree::Stock::Coordinator.new(self).shipments
    end

    def apply_free_shipping_promotions

      Spree::PromotionHandler::FreeShipping.new(self).activate
      shipments.each do |shipment|
        shipment.shipping_rates.each { |rate| ItemAdjustments.new(rate).update }
      end

      updater.update_adjustment_total
      updater.update_shipment_total
      persist_totals
    end

    # Clean shipments and make order back to address state
    #
    # At some point the might need to force the order to transition from address
    # to delivery again so that proper updated shipments are created.
    # e.g. customer goes back from payment step and changes order items
    def ensure_updated_shipments
      if shipments.any? && !self.completed?
        delete_all_shipping_rate_adjustments
        self.shipments.destroy_all
        self.update_column(:shipment_total, 0)
        restart_checkout_flow
      end
    end

    def restart_checkout_flow
      self.update_columns(
      state: 'cart',
      updated_at: Time.now,
      )
      self.next! if self.line_items.size > 0
    end

    def refresh_shipment_rates
      shipments.map(&:refresh_rates)
    end

    def shipping_eq_billing_address?
      (bill_address.empty? && ship_address.empty?) || bill_address.same_as?(ship_address)
    end

    def set_shipments_cost
      shipments.each(&:update_shipping_rate_adjustments)
      updater.update_shipment_total
      persist_totals
    end

    def is_risky?
      self.payments.risky.count > 0
    end

    def canceled_by(user)
      self.transaction do
        cancel!
        self.update_columns(
        canceler_id: user.id,
        canceled_at: Time.now,
        )
      end
    end

    def approved_by(user)
      self.transaction do
        approve!
        self.update_columns(
        approver_id: user.id,
        approved_at: Time.now,
        )
      end
    end

    def approved?
      !!self.approved_at
    end

    def can_approve?
      !approved?
    end

    def consider_risk
      if is_risky? && !approved?
        considered_risky!
      end
    end

    def considered_risky!
      update_column(:considered_risky, true)
    end

    def approve!
      update_column(:considered_risky, false)
    end

    # moved from api order_decorator. This is a better place for it.
    def update_line_items(line_item_params)
      return if line_item_params.blank?
      line_item_params.each_value do |attributes|
        if attributes[:id].present?
          self.line_items.find(attributes[:id]).update_attributes!(attributes)
        else
          self.line_items.create!(attributes)
        end
      end
      self.ensure_updated_shipments
    end

    def reload(options=nil)
      remove_instance_variable(:@tax_zone) if defined?(@tax_zone)
      super
    end

    def tax_total
      included_tax_total + additional_tax_total
    end

    def quantity
      line_items.sum(:quantity)
    end

    def has_non_reimbursement_related_refunds?
      refunds.non_reimbursement.exists? ||
      payments.offset_payment.exists? # how old versions of spree stored refunds
    end

    def active_hold_note
      order_notes.last if on_hold?
    end

    def on_hold?
      %(warehouse_on_hold customer_service_on_hold).include?(state)
    end

    # Removing as this is not default spree behaviour
    def prune_line_items!
      if self.completed?
        Rails.logger.error "spree_order: Cannot prune line items from a completed order: #{self.id}"
      else
        line_items_to_delete = self.line_items.select {|li| li.variant.deleted? }
        if line_items_to_delete.any?
          order_contents = OrderContents.new(self)
          variant_names = []

          line_items_to_delete.each do |line_item|
            variant = line_item.variant
            display_name = %Q{#{variant.name}}
            display_name += %Q{ (#{variant.options_text})} unless variant.options_text.blank?
            variant_names << display_name

            order_contents.remove_by_line_item(line_item, line_item.quantity, {})
          end

          errors.add(:base, Spree.t(:line_items_pruned, :items => variant_names.to_sentence))
        end
      end
    end

    def express?
      shipments.any?(&:express?)
    end

    def self.express
      Spree::Order.joins(shipments: [shipping_rates: :shipping_method]).
      where('spree_shipping_methods.express = true and spree_shipping_rates.selected = true').uniq
    end

    private

    def self.ransackable_scopes(auth_object = nil)
      %i(express)
    end

    def delete_all_shipping_rate_adjustments
      ::Adjustments::Selector.new(all_adjustments).shipping_rate.map(&:delete)
    end

    def link_by_email
      self.email = user.email if self.user
    end

    # Determine if email is required (we don't want validation errors before we hit the checkout)
    def require_email
      true unless new_record? or ['cart', 'address'].include?(state)
    end

    def ensure_line_items_present
      unless line_items.present?
        errors.add(:base, Spree.t(:there_are_no_items_for_this_order)) and return false
      end
    end

    def has_available_shipment
      return unless has_step?("delivery")
      return unless has_step?(:address) && address?
      return unless ship_address && ship_address.valid?
      # errors.add(:base, :no_shipping_methods_available) if available_shipping_methods.empty?
    end

    def ensure_available_shipping_rates
      if shipments.empty? || shipments.any? { |shipment| shipment.shipping_rates.blank? }
        # After this point, order redirects back to 'address' state and asks user to pick a proper address
        # Therefore, shipments are not necessary at this point.
        shipments.destroy_all
        errors.add(:base, Spree.t(:items_cannot_be_shipped)) and return false
      end
    end

    def after_cancel
      shipments.each { |shipment| shipment.cancel! }
      payments.completed.each { |payment| payment.cancel! }
      send_cancel_email
      self.update!
    end

    def send_cancel_email
      unless internal?
        OrderMailer.cancel_email(self.id).deliver
      end
    end

    def after_resume
      shipments.each { |shipment| shipment.resume! }
      consider_risk
    end

    def use_billing?
      @use_billing == true || @use_billing == 'true' || @use_billing == '1'
    end

    def set_currency
      self.currency = Spree::Config[:currency] if self[:currency].nil?
    end

    def create_token
      self.guest_token ||= loop do
        random_token = SecureRandom.urlsafe_base64(nil, false)
        break random_token unless self.class.exists?(guest_token: random_token)
      end
    end
  end
end
