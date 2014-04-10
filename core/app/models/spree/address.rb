module Spree
  class Address < ActiveRecord::Base
    belongs_to :country, class_name: "Spree::Country"
    belongs_to :state, class_name: "Spree::State"

    has_many :shipments, inverse_of: :address

    validates :firstname, :lastname, :address1, :city, :country, presence: true
    validates :zipcode, presence: true, if: :require_zipcode?
    validates :phone, presence: true, if: :require_phone?

    validate :state_validate
    validate :phone_validate

    alias_attribute :first_name, :firstname
    alias_attribute :last_name, :lastname

    # Disconnected since there's no code to display error messages yet OR matching client-side validation
    def phone_validate
      if phone.blank?
        errors.add :phone, :invalid
        return 
      end
      n_digits = phone.scan(/[0-9]/).size

      errors.add :phone, :too_long if n_digits > 15
      
      valid_chars = (phone =~ /^[-+()\/\s\d]+$/)
      errors.add :phone, :invalid unless (n_digits > 5 && valid_chars)
    end

    def self.build_default
      country = Spree::Country.find(Spree::Config[:default_country_id]) rescue Spree::Country.first
      new(country: country)
    end

    def self.default(user = nil, kind = "bill")
      if user
        user.send(:"#{kind}_address") || build_default
      else
        build_default
      end
    end

    # Can modify an address if it's not been used in an order (but checkouts controller has finer control)
    # def editable?
    #   new_record? || (shipments.empty? && checkouts.empty?)
    # end

    def full_name
      "#{firstname} #{lastname}".strip
    end

    def state_text
      state.try(:abbr) || state.try(:name) || state_name
    end

    def same_as?(other)
      return false if other.nil?
      attributes.except('id', 'updated_at', 'created_at') == other.attributes.except('id', 'updated_at', 'created_at')
    end

    alias same_as same_as?

    def to_s
      "#{full_name}: #{address1}"
    end

    def clone
      self.class.new(self.attributes.except('id', 'updated_at', 'created_at'))
    end

    def ==(other_address)
      self_attrs = self.attributes
      other_attrs = other_address.respond_to?(:attributes) ? other_address.attributes : {}

      [self_attrs, other_attrs].each { |attrs| attrs.except!('id', 'created_at', 'updated_at', 'order_id') }

      self_attrs == other_attrs
    end

    def empty?
      attributes.except('id', 'created_at', 'updated_at', 'order_id', 'country_id').all? { |_, v| v.nil? }
    end

    def in_zone?(zone_name)
      zone = Spree::Zone.where(name: zone_name).first
      if zone
        zone.zone_members.map(&:zoneable_id).include?(country_id)
      else
        raise "Unknow Zone named: '#{zone_name}'"
      end
    end
    
    # Generates an ActiveMerchant compatible address hash
    def active_merchant_hash
      {
        name: full_name,
        address1: address1,
        address2: address2,
        city: city,
        state: state_text,
        zip: zipcode,
        country: country.try(:iso),
        phone: phone
      }
    end

    def require_phone?
      true
    end

    def require_zipcode?
      true
    end

    private
      def state_validate
        # Skip state validation without country (also required)
        # or when disabled by preference
        return if country.blank? || !Spree::Config[:address_requires_state]
        return unless country.states_required

        # ensure associated state belongs to country
        if state.present?
          if state.country == country
            self.state_name = nil #not required as we have a valid state and country combo
          else
            if state_name.present?
              self.state = nil
            else
              errors.add(:state, :invalid)
            end
          end
        end

        # ensure state_name belongs to country without states, or that it matches a predefined state name/abbr
        if state_name.present?
          if country.states.present?
            states = country.states.find_all_by_name_or_abbr(state_name)

            if states.size == 1
              self.state = states.first
              self.state_name = nil
            else
              errors.add(:state, :invalid)
            end
          end
        end

        # ensure at least one state field is populated
        errors.add :state, :blank if state.blank? && state_name.blank?
      end
  end
end
