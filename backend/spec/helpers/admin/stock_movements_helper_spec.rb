# coding: UTF-8
require 'spec_helper'

describe Spree::Admin::StockMovementsHelper, :type => :helper do

  describe "#pretty_originator" do

    context "transfering between two locations" do
      it "returns link to stock transfer" do
        stock_transfer = Spree::StockTransfer.create(reference: 'PO123')
        stock_movement = Spree::StockMovement.new(originator: stock_transfer)
        allow(stock_movement).to receive(:stock_item).and_return double.as_null_object
        stock_movement.save!(validate: false)

        helper.pretty_originator(stock_transfer.stock_movements.last).should eq stock_transfer.number
      end
    end
  end

end