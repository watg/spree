require 'spec_helper'

describe Spree::Admin::GangMembersController, type: :controller do
  let(:gang_member) {create(:gang_member)}
  stub_admin_user

  it 'can edit gang member' do
    spree_get :edit, id: gang_member.permalink
    expect(response).to be_success
    expect(assigns(:gang_member)).to eq(gang_member)
  end

end
