require "spec_helper"
require_relative "indexable_shared_examples"

class SomePage
  include Indexable
end

describe SomePage do
  it_behaves_like Indexable
end
