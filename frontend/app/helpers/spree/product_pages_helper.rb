module Spree
  module ProductPagesHelper
    def safe_tag(tag)
      tag.gsub(/[^\w\s]/, '').strip.gsub(/\s+/, '-').downcase
    end

    def safe_tags(tags)
      tags.map { |t| safe_tag(t) }
    end

    def safe_tag_list(tags)
      safe_tags(tags).join(' ')
    end
  end
end
