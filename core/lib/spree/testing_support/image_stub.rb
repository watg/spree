# Make tests run faster by stubbing out the post processing
class Paperclip::Attachment
  def post_process
  end
end

module Paperclip
  def self.run cmd, arguments = "", interpolation_values = {}, local_options = {}
    cmd == 'convert' ? nil : super
  end
end

RSpec.configure do |config|
  config.before(:each) do
    Spree::Image.any_instance.stub(:save_attached_files).and_return(true)
  end
end