require 'spec_helper'

describe Spree::AssemblyDefinitionPresenter do

  let(:assembly_definition) { Spree::AssemblyDefinition.new() }

  let(:target) { Spree::Target.new }

  let(:context) { { currency: 'USD'}}
  subject { described_class.new(assembly_definition, view, context.merge(target: target)) }

  context "#images" do
    let(:images) { double() }

    it "should call #images and pass a target" do
      expect(images).to receive(:with_target).with(target).and_return true
      expect(assembly_definition).to receive(:images).and_return(images)
      expect(subject.images).to eq true
    end
  end
end
