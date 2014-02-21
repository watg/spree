require 'spec_helper'

describe Spree::CheckoutController, type: :controller do
  let(:order) { FactoryGirl.create(:order_with_pending_payment) }
  
  before do
    subject.stub :authorize! => true, :ensure_api_key => true
    order.stub :can_go_to_state? => false
    subject.stub(:current_order).and_return(order)
    subject.stub(:set_current_order).and_return(order)
  end
  
  context "newsletter subscription" do
    let(:params) { {mc: {list_name: 'WATG newsletter', signupEmail: 'luther@bbc.co.uk', subscribe: true}, state: 'delivery'} }

    it "should subscribe customer" do
      expected_data = {
        email: params[:mc][:signupEmail],
        action: :subscribe,
        request_params: params[:mc].to_json
      }
      
      Mailchimp.should_receive(:new).with(expected_data) 
      subject.send(:update_mailchimp, params[:mc])
    end

    it "should unsubscribe customer" do
      expected_data = {
        email: params[:mc][:signupEmail],
        action: :unsubscribe,
        request_params: params[:mc].merge(subscribe: '').to_json
      }
      
      Mailchimp.should_receive(:new).with(expected_data)
      subject.send(:update_mailchimp, params[:mc].merge(subscribe: ''))
      
    end
  end
  
  context "order with a pending payment" do

    it "should not display payment page" do
      get :edit, state: 'payment', :use_route => :spree
      expect(response.status).to eq(302)
      flash[:error].should_not be_blank
    end

  end
end
