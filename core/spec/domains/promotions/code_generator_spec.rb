require 'spec_helper'

RSpec.describe Promotions::CodeGenerator, type: :domains do
  let(:generator) { Promotions::CodeGenerator.new() }

  it "generates a new code" do
    code = generator.generate
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

    generator.generate

    expect(code1).not_to eq(code2)
  end

  context "provide prefix" do
    let(:generator) { Promotions::CodeGenerator.new(prefix: 'PRE-') }

    it "uses an optional prefix" do
      code = generator.generate
      expect(code.size).to eq(10)
      expect(code).to start_with("PRE-")
    end

    context "provide size" do
      let(:generator) { Promotions::CodeGenerator.new(size: 4) }

      it "uses an optional size" do
        code = generator.generate
        expect(code.size).to eq(4)
      end
    end

  end
end
