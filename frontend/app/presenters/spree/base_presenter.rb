module Spree
  class BasePresenter

    attr_accessor :currency, :target, :device

    def initialize(object, template, context={})
      @object = object
      @template = template
      @currency = context.fetch(:currency, nil)
      @target = context[:target] || nil
      @device = context[:device] || :desktop
      @context = context
    end

    def self.presents(name)
      define_method(name) do
        @object
      end
    end

    private

    def is_mobile?
      device == :mobile
    end

    def is_desktop?
      device == :desktop
    end

    def context
      @context
    end

    def template
      @template
    end

    def h
      template
    end

    def url_encode(string)
      h.send(:url_encode, string)
    end

  end
end
