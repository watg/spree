Spree::Core::Engine.config.to_prepare do
  if Spree.user_class
    Spree.user_class.class_eval do

      include Spree::UserReporting
      include Spree::UserApiAuthentication
      has_and_belongs_to_many :spree_roles,
                              :join_table => 'spree_roles_users',
                              :foreign_key => "user_id",
                              :class_name => "Spree::Role"

      has_many :spree_orders, :foreign_key => "user_id", :class_name => "Spree::Order"

      belongs_to :ship_address, :class_name => 'Spree::Address'
      belongs_to :bill_address, :class_name => 'Spree::Address'

      # has_spree_role? simply needs to return true or false whether a user has a role or not.
      def has_spree_role?(role_in_question)
        spree_roles.where(:name => role_in_question.to_s).any?
      end

      def last_incomplete_spree_order
        spree_orders.incomplete.where(:created_by_id => self.id).order('created_at DESC').first
      end

      def self.find_or_create_unenrolled(email, tracking_cookie = nil)
        # if the same user is trying to register another e-mail address, we want to assign a different uuid
        email = email.downcase
        if !tracking_cookie or Spree.user_class.where(uuid: tracking_cookie).first
          tracking_cookie = UUID.generate
        end
        Spree.user_class.where(email: email).first_or_create do |user|
          password = UUID.generate
          user.email = email
          user.uuid = tracking_cookie
          user.enrolled = false
          user.password = password
          user.password_confirmation = password
        end
      end
      
      def self.customer_has_subscribed?(email)
        where(email: email, subscribed: true).any?
      end

    end
  end
end
