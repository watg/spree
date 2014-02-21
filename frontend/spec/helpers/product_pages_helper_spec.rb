require 'spec_helper'

describe Spree::ProductPagesHelper, type: :helper do
  describe "safe_tag" do
    it "lowercases, removes non-alphanumeric characters and replaces spaces with -" do
      tag_name = "Tag with 2 <numbers> and 1 & and a *"
      expect(helper.safe_tag(tag_name)).to eq("tag-with-2-numbers-and-1-and-a")
    end
  end

  describe "safe_tags" do
    it "makes all the tags in the array safe" do
      expect(helper).to receive(:safe_tag).with("tag1").and_return("safe1")
      expect(helper).to receive(:safe_tag).with("tag2").and_return("safe2")

      tags = ["tag1", "tag2"]
      expect(helper.safe_tags(tags)).to eq(["safe1", "safe2"])
    end
  end

  describe "safe_tag_list" do
    it "joins safe tags with spaces" do
      expect(helper).to receive(:safe_tag).with("tag1").and_return("safe1")
      expect(helper).to receive(:safe_tag).with("tag2").and_return("safe2")

      tags = ["tag1", "tag2"]
      expect(helper.safe_tag_list(tags)).to eq("safe1 safe2")
    end
  end
end
