module Spree
  module Feed
    class Planner
      attr_reader :list

      def initialize(*requirements)
        @list = merge_lists(requirements)
      end

      def plan
        list.inject({}) do |movements, requirement|
          loc, variants = requirement
          variants.each_pair do |variant, count|
            remaining = count
            loc.feeders.each do |feeder|
              pick = [feeder.count_on_hand(variant), remaining].min
              if pick > 0
                remaining -= pick
                movements[loc] ||= {}
                movements[loc][feeder] ||= {}
                movements[loc][feeder][variant] = pick
              end
              break if remaining <= 0
            end
          end
          movements
        end
      end

      private

      def merge_lists(requirements)
        lists = requirements.map { |requirement| requirement.new.list }

        merged_list = Hash.new { |hash, key| hash[key] = Hash.new(0) }

        lists.each do |list|
          list.each_pair do |location, variants|
            variants.each do |variant, count|
              merged_list[location][variant] += count
            end
          end
        end

        merged_list
      end
    end
  end
end
