Spree::Core::Engine.config.to_prepare do
  if Spree.user_class
    Spree.user_class.class_eval do
      has_and_belongs_to_many :spree_roles,
                              :join_table => 'spree_roles_users',
                              :foreign_key => "user_id",
                              :class_name => "Spree::Role"

      has_many :spree_orders, :foreign_key => "user_id", :class_name => "Spree::Order"

      belongs_to :ship_address, :class_name => 'Spree::Address'
      belongs_to :bill_address, :class_name => 'Spree::Address'

      before_validation do
        self.uuid ||= Spree.user_class.generate_token(:uuid) if self.respond_to?(:uuid)
      end

      validates :uuid, uniqueness: true

      # has_spree_role? simply needs to return true or false whether a user has a role or not.
      def has_spree_role?(role_in_question)
        spree_roles.where(:name => role_in_question.to_s).any?
      end

      def last_incomplete_spree_order
        spree_orders.incomplete.where(:created_by_id => self.id).order('created_at DESC').first
      end

      private

      # Generate a friendly string randomically to be used as token.
      def self.friendly_token
        SecureRandom.base64(15).tr('+/=', '-_ ').strip.delete("\n")
      end

      # Generate a token by looping and ensuring does not already exist.
      def self.generate_token(column)
        loop do
          token = friendly_token
          break token unless where(column => token).first
        end
      end



    end
  end
end
