require 'spec_helper'

describe ApplicationController, type: :controller do

  context "device" do

    context "user agent recongised" do
      it "sets the correct devise" do
        request = double(:user_agent => 'iPhone' )
        allow_any_instance_of(ApplicationController).to receive(:request).and_return(request)
        expect(ApplicationController.new.device).to eq :mobile
      end
    end

    context "no user_agent" do
      it "sets the correct device to desktop" do
        request = double(:user_agent => 'asdaklsdj' )
        allow_any_instance_of(ApplicationController).to receive(:request).and_return(request)
        expect(ApplicationController.new.device).to eq :desktop
      end
    end

  end

end
