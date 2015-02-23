require 'spec_helper'

RSpec.describe Spree::Promotion::CodeGenerator, :type => :model do
  let(:generator) { Spree::Promotion::CodeGenerator }

  it "generates a new code" do
    code = generator.run
    expect(code).to be_a(String)
    expect(code.size).to eq(6)
  end

  it "ensures the code is unique" do
    active = double(Spree::Promotion)
    allow(Spree::Promotion).to receive(:active).and_return(active)

    code1 = nil
    expect(active).to receive(:where) do |c|
      code1 = c
      [Spree::Promotion.new] # fake finding an existing code
    end

    code2 = nil
    expect(active).to receive(:where) do |c|
      code2 = c
      [] # fake finding no matching code
    end

    generator.run

    expect(code1).not_to eq(code2)
  end

  it "uses an optional prefix" do
    code = generator.run(prefix: "PRE-")
    expect(code.size).to eq(10)
    expect(code).to start_with("PRE-")
  end

  it "uses an optional size" do
    code = generator.run(size: 4)
    expect(code.size).to eq(4)
  end
end
