module Spree
  class SuitePresenter < BasePresenter
    presents :suite

    def initialize(object, template, context={})
      super(object, template, context)
    end

    def self.desktop_image_size(counter)
      counter % 9 == 0  ? :large : :small
    end

    def tabs
      @tabs ||= suite.tabs.select { |tab| tab.in_stock_cache }.sort_by(&:position)
    end

    def image
      @image ||= suite.image
    end

    def suite_tab_presenters
      tabs.map do |tab|
        presenter = suite_tab_presenter(tab)
        yield presenter if block_given?
        presenter
      end
    end

    def available_stock?
      tabs.any?
    end

    ## Images
    def image_url(counter = 0)
      if image.present?
        style = image_size(counter)
        image.attachment.url(style)
      else
        placeholder_image
      end
    end

    def container_class(counter=0)
      image_size(counter) == :large ? 'large-8' : 'large-4'
    end

    def image_alt
      alt = image.try(:alt)
      alt.blank? ? title : alt
    end

    def header_style
      case suite.template_id
      when Spree::Suite::LARGE_TOP
        classes = "large top"
      when Spree::Suite::SMALL_BOTTOM
        classes = "small bottom"
      else
        classes = "small bottom"
      end

      if suite.inverted?
        classes += " inverted"
      end

      classes
    end

    def link_to_first_tab_in_stock
      if first_tab = suite_tab_presenters.detect { |stp| stp.in_stock? }
        first_tab.link_to
      end
    end

    def title
      @title ||= suite.title
    end

    def permalink
      @permalink ||= suite.permalink
    end

    def target
      @target ||= suite.target
    end

    def id
      @id ||= suite.id
    end

    def title_size_class
      word_lengths = suite.title.split.map(&:length)
      if word_lengths.detect { |word| word > 8 }
        "mini"
      elsif word_lengths.reduce(:+) >= 12
        "small"
      elsif word_lengths.detect { |word| word  >= 5 } || word_lengths.reduce(:+) >= 10
        "medium"
      else
        "large"
      end
    end

    def tab_grid_class(i)
      if i == 0
        'push-3'
      else
        'pull-3'
      end
    end

    private

    def placeholder_image
      if is_mobile?
        h.image_path("product-group/placeholder-150x192.gif")
      else
        h.image_path("product-group/placeholder-470x600.gif")
      end
    end

    def image_size(counter)
      if is_mobile?
        :mobile
      else
        SuitePresenter.desktop_image_size(counter)
      end
    end

    def render_out_of_stock
      h.content_tag(:span, 'out-of-stock', class: 'price', itemprop: 'price')
    end

    def suite_tab_presenter(tab)
      @suite_tab_presenter ||= {}
      @suite_tab_presenter[tab] ||= SuiteTabPresenter.new(tab, template, {
        suite: suite,
        currency: currency,
        target: target,
        device: device
      })
      @suite_tab_presenter[tab]
    end

  end
end
