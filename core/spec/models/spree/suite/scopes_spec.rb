require 'spec_helper'

describe "Suite scopes" do
  let!(:suite) { create(:suite) }

  context "A product assigned to parent and child taxons" do
    before do
      @taxonomy = create(:taxonomy)
      @root_taxon = @taxonomy.root

      @parent_taxon = create(:taxon, :name => 'Parent', :taxonomy_id => @taxonomy.id, :parent => @root_taxon)
      @child_taxon = create(:taxon, :name =>'Child 1', :taxonomy_id => @taxonomy.id, :parent => @parent_taxon)
      @parent_taxon.reload # Need to reload for descendents to show up

      suite.taxons << @parent_taxon
      suite.taxons << @child_taxon
    end

    # This spec does not make sense anymore as we propogate
    # the classifications up the ancestor tree now
    #xit "calling suite.in_taxon returns suite in child taxons" do
    # suite.taxons -= [@child_taxon]
    # suite.taxons.count.should == 1
    #
    #  Spree::Suite.in_taxon(@parent_taxon).should include(suite)
    #end

    it "calling Suite.in_taxon should not return duplicate records" do
      Spree::Suite.in_taxon(@parent_taxon).to_a.count.should == 1
    end

    it "orders suites based on their ordering within the classification" do
      suite_2 = create(:suite)
      suite_2.taxons << @parent_taxon

      suite_root_classification = Spree::Classification.find_by(:taxon => @parent_taxon, :suite => suite)
      suite_root_classification.update_column(:position, 1)

      suite_2_root_classification = Spree::Classification.find_by(:taxon => @parent_taxon, :suite => suite_2)
      suite_2_root_classification.update_column(:position, 2)

      Spree::Suite.in_taxon(@parent_taxon).should == [suite, suite_2]
      suite_2_root_classification.insert_at(1)
      Spree::Suite.in_taxon(@parent_taxon).should == [suite_2, suite]
    end
  end
end


