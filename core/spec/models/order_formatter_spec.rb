require 'spec_helper'

describe Spree::OrderFormatter do
  let(:order) { create(:order) }
  subject { Spree::OrderFormatter.new(order) }

  describe 'Initialization' do
    it 'Sets up the @order variable' do
      expect(subject.instance_variable_get(:@order)).to eql(order)
    end
  end

  describe 'Data Formatting' do
    subject { Spree::OrderFormatter.new(order).order_data }

    it { expect(subject).to have_key(:order_number) }
    it { expect(subject).to have_key(:email) }
    it { expect(subject).to have_key(:items) }
    it { expect(subject).to have_key(:items_total) }
    it { expect(subject).to have_key(:shipment_total) }
    it { expect(subject).to have_key(:adjustments) }
    it { expect(subject).to have_key(:promotions) }
    it { expect(subject).to have_key(:adjustments_total) }
    it { expect(subject).to have_key(:delivery_time) }
    it { expect(subject).to have_key(:currency) }
    it { expect(subject).to have_key(:payment_total) }
  end
end
