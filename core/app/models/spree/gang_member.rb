module Spree
  class GangMember < ActiveRecord::Base 

    TAXONOMY = 'Gang Makers'

    # TODO: Valifations on first name and last name
    #
    # uniq on nickname
    # upload a pic mandatory
    # validation on profile 
    # search by product_group and gang_member
    # get profile and pic on product page
    #
    #
    # Tests
    # after_update find taxon, is it the same as the nickname
    #   if not rename taxon, and link all the products to it 
    
    # This has been disabled until we get clearer requirements ( David D 23-7-13 )
    #before_save :set_nickname_as_taxon

    validates :firstname, :presence => true
    validates_uniqueness_of :firstname, :scope => :lastname

    has_many :products

    default_styles = ActiveSupport::JSON.decode(Spree::Config[:attachment_styles]).symbolize_keys!

    has_attached_file :avatar,
      :styles        => { :avatar => "150x150>", :mini => default_styles[:mini] },
      :default_style => :small,
      :url           => "/spree/gang_members/:id/:style/:basename.:extension",
      :path          => ":rails_root/public/spree/gang_members/:id/:style/:basename.:extension",
      :convert_options =>  { :all => '-strip -auto-orient' }

    process_in_background :avatar

    include Spree::Core::S3Support
    supports_s3 :avatar

    Spree::GangMember.attachment_definitions[:avatar][:url] = Spree::Config[:attachment_url]
    Spree::GangMember.attachment_definitions[:avatar][:default_url] = Spree::Config[:attachment_default_url]
    Spree::GangMember.attachment_definitions[:avatar][:default_style] = Spree::Config[:attachment_default_style]
    Spree::GangMember.attachment_definitions[:avatar][:s3_host_name] = Spree::Config[:s3_host_alias]

    def name
      nickname 
    end

    def taxon
      taxonomy.root.children.where( :name => nickname ).first
    end

    def visible?
      visible
    end

    private

    def taxonomy
      Spree::Taxonomy.find_or_create_by_name(TAXONOMY)
    end

    def set_nickname_as_taxon

      # Find previous taxon
      # create new taxon
      # Find all products that have previous taxon
      # delete the taxon
      # add the new taxon

      puts taxonomy
      unless taxonomy.root.children.find_by_name(nickname)
        taxon = Taxon.new(:name => nickname)
        taxon.taxonomy_id = taxonomy.id 
        taxon.parent_id = taxonomy.root.id
        taxon.save
      end
    end

  end
end
