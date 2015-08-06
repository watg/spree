require 'spec_helper'

describe Spree::Api::ProductPartsController do
  render_views

  let(:variant_assembly) { create(:variant)  }
  let(:product)          { create(:product, product_type: type) }
  let(:type)             { create(:product_type, :kit) }

  let(:variant_part)     { create(:base_variant)  }
  let(:part)             { variant_part.product  }

  let!(:product_part)    { Spree::ProductPart.create(opts)  }
  let(:opts)             { { product: product, part: part }  }
  let!(:variants)        { [create(:variant)]  }
  let!(:attributes)      { [:id, :options_text]  }

  before do
    stub_authentication!
    expect_any_instance_of(Spree::ProductPart).to receive(:variants).and_return(variants)
  end

  it "list available variants for an product part" do
    api_get :variants, {id: product_part.id}
    expect(json_response["id"]).to eq(product_part.id)
    expect(json_response["variants"][0]).to have_attributes(attributes)
  end
end
