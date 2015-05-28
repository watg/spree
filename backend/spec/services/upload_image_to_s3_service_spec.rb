require "spec_helper"

describe Spree::UploadImageToS3Service do
  subject { described_class }

  let(:params) do
    {
      "url" => "https://amazon/thefile.jpg",
      "filepath" => "/uploads/thefile.jpg",
      "filename" => "thefile.jpg",
      "filesize" => "165405",
      "filetype" => "image/jpeg",
      "unique_id" => "booyeah",
      "image" =>  {
        "direct_upload_url" => "https://watg-development.s3.amazonaws.com/uploads%2F1432291472710-booyeah-f334fdca469bb0d20e806988c733959d%2Fthefile.jpg"
      }
    }
  end

  let(:image) { create(:image) }

  context "#run" do
    context "when invalid" do
      context "missing image params" do
        it "adds error message" do
          outcome = subject.run(image: image)
          expect(outcome.errors.messages).to include(params: ["is required"])
          expect(outcome.errors.full_messages.to_sentence).to eq("Params is required")
        end
      end

      context "missing main params" do
        it "adds error message" do
          outcome = subject.run(params: params)
          expect(outcome.errors.messages).to include(image: ["is required"])
          expect(outcome.errors.full_messages.to_sentence).to eq("Image is required")
        end
      end

      context "image does not match upload url format" do
        let(:invalid_upload_url) do
          {
            "url" => "https://amazon/thefile.jpg",
            "filepath" => "/uploads/thefile.jpg",
            "filename" => "thefile.jpg",
            "filesize" => "165405",
            "filetype" => "image/jpeg",
            "unique_id" => "booyeah",
            "image" =>  {
              "direct_upload_url" => "https://amazon%thefile.jpg"
            }
          }
        end

        it "adds an error message" do
          outcome = subject.run(image: image, params: invalid_upload_url)
          expect(outcome.valid?).to eq false
          expect(outcome.errors.messages)
            .to include(direct_upload_url: ["Url not correctly formatted"])
          expect(outcome.errors.full_messages.to_sentence)
            .to eq("Direct upload url Url not correctly formatted")
        end
      end
    end

    context "valid image" do
      it "uploads image" do
        outcome = subject.run(image: image, params: params)
        expect(outcome.valid?).to eq true
        expect(outcome.errors.full_messages.to_sentence).to eq("")
      end
    end
  end
end
