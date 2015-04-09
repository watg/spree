require "spec_helper"

shared_examples_for IndexableInterface do
  [:suites, :num_pages].each do |raising_error_method|
    specify { expect { subject.send(raising_error_method) }.not_to raise_error }
  end

  [:title, :meta_description, :meta_keywords, :meta_title, :show_all].each do |respond_method|
    it { is_expected.to respond_to(respond_method) }
  end
end
