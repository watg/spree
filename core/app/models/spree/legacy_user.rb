# Default implementation of User.  This class is intended to be modified by extensions (ex. spree_auth_devise)
module Spree
  class LegacyUser < ActiveRecord::Base
    include Core::UserAddress

    self.table_name = 'spree_users'
    has_many :orders, foreign_key: :user_id

    before_destroy :check_completed_orders

    class DestroyWithOrdersError < StandardError; end

    def has_spree_role?(role)
      true
    end

    def self.find_or_create_unenrolled(email, tracking_cookie)
      # if the same user is trying to register another e-mail address, we want to assign a different uuid
      if Spree::LegacyUser.where(uuid: tracking_cookie).first
        tracking_cookie = UUID.generate
      end
      Spree::LegacyUser.where(email: email).first_or_create do |user|
        password = 'random_password'
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

    attr_accessor :password
    attr_accessor :password_confirmation

    private

      def check_completed_orders
        raise DestroyWithOrdersError if orders.complete.present?
      end
  end
end
