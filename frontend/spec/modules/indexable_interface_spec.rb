require "spec_helper"
require_relative "indexable_shared_examples"

class SomePage
  include IndexableInterface

  def suites
  end

  def num_pages
  end
end

describe SomePage do
  it_behaves_like IndexableInterface
end
