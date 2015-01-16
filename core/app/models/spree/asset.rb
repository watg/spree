module Spree
  class Asset < Spree::Base
    acts_as_paranoid

    belongs_to :viewable, polymorphic: true, touch: true
    acts_as_list scope: [:viewable_id, :viewable_type, :deleted_at]

    belongs_to :target
  end

end
