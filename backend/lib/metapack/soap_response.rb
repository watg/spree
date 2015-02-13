module Metapack
  class SoapResponse
    def initialize(http_response)
      @http_response = http_response
    end

    def success?
      @http_response.code.to_i == 200
    end

    def body
      @http_response.body
    end

    def find(css_selector)
      doc.at_css(css_selector).try(:text)
    end

    def find_all(css_selector, children)
      result = []
      doc.css(css_selector).each do |node|
        item = {}
        children.each do |child_selector|
          item[child_selector] = node.at_css(child_selector.to_s).text
        end
        result << item
      end
      result
    end

    private

    def doc
      Nokogiri::XML(@http_response.body)
    end
  end
end
