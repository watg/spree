module Metapack
  class SoapTemplate
    def initialize(template_name, hash = {})
      hash.each_pair do |k, v|
        self.class.send(:define_method, k.to_sym) do
          v
        end
      end
      @template_name = template_name
    end

    def template_path
      File.expand_path("../templates/#{@template_name}.xml.erb", __FILE__)
    end

    def escape(str)
      str.encode(xml: :text)
    end

    def xml
      template = File.read(template_path)
      ERB.new(template, 0, '>').result(binding)
    end
  end
end
