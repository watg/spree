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
    validates_uniqueness_of :firstname, :scope => :lastname #? are you sure about this validation?

    has_many :products

    make_permalink order: :firstname

    has_attached_file :avatar,
      :styles        => { :avatar => "150x150>", :mini => "66x84>" },
      :default_style => :mini,
      :convert_options =>  { :all => '-strip -auto-orient' }

    process_in_background :avatar

    def name
      nickname 
    end

    def taxon
      taxonomy.root.children.where( :name => nickname ).first
    end

    def visible?
      visible
    end

    # Peruvian (id=14) or WATG (id=2)
    def peruvian?
      (id == 14 or id == 2) 
    end

    def to_param
      if permalink.present? 
        permalink
      else
        self.with_lock do
          other = GangMember.where("permalink LIKE ?", "#{firstname.to_s.to_url}%").first
          if other.present?
            return firstname.to_s.to_url
          else
            return firstname.to_s.to_url + "-1"
          end
        end
      end
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
