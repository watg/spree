module Spree
  class ZoneMember < ActiveRecord::Base
    belongs_to :zone, class_name: 'Spree::Zone', counter_cache: true
    belongs_to :zoneable, polymorphic: true
    validate :if_already_used

    def name
      return nil if zoneable.nil?
      zoneable.name
    end

    def if_already_used
      zone_member = Spree::ZoneMember.where(zoneable_id: zoneable_id, zoneable_type: zoneable_type).where.not(zone_id: zone_id).first
      if zone_member
        errors.add(:zoneable, "already used in zone: "  + zone_member.zone.name)
      end
    end

  end
end
