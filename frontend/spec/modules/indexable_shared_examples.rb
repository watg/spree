require "spec_helper"

shared_examples_for Indexable do
  it { is_expected.to respond_to(:title) }
  it { is_expected.to respond_to(:meta_description) }
  it { is_expected.to respond_to(:meta_keywords) }
  it { is_expected.to respond_to(:meta_title) }
  it { is_expected.to respond_to(:suites) }
  it { is_expected.to respond_to(:num_pages) }
  it { is_expected.to respond_to(:show_all) }
end
