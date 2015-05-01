require "spec_helper"

describe "user receives email" do
  let(:order)       { create(:order) }
  let(:shipment)    { create(:shipment, order: order) }
  let(:line_item)   { create(:line_item, order: order) }
  let(:kit)         { create(:product_type, :kit) }
  let(:job)         { Delayed::Job.last }
  let(:handler)     { YAML.load(job.handler).object }
  let(:mail_header) { ActionMailer::Base.deliveries.last.header }
  let(:template)    { mail_header['X-MC-Template'].value }
  let(:recipient)   { JSON.load(mail_header['X-MC-MergeVars'].value)['name'] }

  before do
    line_item.product.update(product_type: kit)
    shipment.state = "ready"
    allow(shipment).to receive_messages determine_state: "shipped"
    Timecop.freeze
  end

  it "dispatches email in 1 month" do
    shipment.update!(order)
    job.invoke_job
    expect(job.run_at.to_s).to eq(30.days.from_now.to_s)
    expect(handler).to be_a(Shipping::KnittingExperienceMailer)
    expect(template).to eq 'en_kits_and_patterns_survey'
    expect(recipient).to eq shipment.address.full_name
  end
end
