module Spree
  class Asset < ActiveRecord::Base
    acts_as_paranoid

    belongs_to :viewable, polymorphic: true, touch: true
    acts_as_list scope: :viewable
  end

end
