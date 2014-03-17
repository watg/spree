module Spree
  class Asset < ActiveRecord::Base
    acts_as_paranoid

    belongs_to :viewable, polymorphic: true, touch: true
    acts_as_list scope: [:viewable_id, :viewable_type]

    belongs_to :target
  end

end
