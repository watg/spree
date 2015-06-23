require "spec_helper"

describe SuiteCategory do
  it { is_expected.to have_many :suites }
end
