require 'spec_helper'

describe Spree::PrintJob do
  let!(:invoice_print_job) { create(:invoice_print_job) }
  let!(:invoice_order) { create(:order, state: :complete, completed_at: Time.now, invoice_print_job: invoice_print_job ) }
  let!(:cancelled_invoice_order) { create(:order, state: :canceled, completed_at: Time.now, invoice_print_job: invoice_print_job) }

  let!(:image_sticker_print_job) { create(:image_sticker_print_job) }
  let!(:image_sticker_order) { create(:order, state: :complete, completed_at: Time.now, image_sticker_print_job: image_sticker_print_job ) }
  let!(:cancelled_image_sticker_order) { create(:order, state: :canceled, completed_at: Time.now, image_sticker_print_job: image_sticker_print_job) }

  describe "#orders" do

    it "returns not cancelled invoice orders" do
      expect(invoice_print_job.orders).to eq [ invoice_order ]
    end

    it "returns not cancelled image sticker orders" do
      expect(image_sticker_print_job.orders).to eq [ image_sticker_order ]
    end

  end

end
