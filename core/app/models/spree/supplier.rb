module Spree
  class Supplier < ActiveRecord::Base 

    TAXONOMY = 'Gang Makers'

    DEFAULT = 'watg'

    DEFAULT_MID_CODE = 'GBGANMAK89LON'
    DEFAULT_COUNTRY_ISO = 'GB'

    validates_uniqueness_of :firstname, :scope => [:lastname, :company_name]

    has_many :inventory_units, inverse_of: :supplier
    has_many :stock_items, inverse_of: :supplier

    has_many :variants, -> { uniq }, through: :stock_items

    belongs_to :country, class_name: 'Spree::Country'

    make_permalink

    has_attached_file :avatar,
      :styles        => { :avatar => "150x150>", :mini => "66x84>" },
      :default_style => :mini,
      :convert_options =>  { :all => '-strip -auto-orient' }

    process_in_background :avatar

    def self.default_country
     Spree::Country.find_by_iso DEFAULT_COUNTRY_ISO 
    end

    def self.default_mid_code
      DEFAULT_MID_CODE
    end

    def self.default
      find_by_name( DEFAULT )
    end

    def name
      string = nil
      if company_name
        string = "Company: #{company_name}"
        if firstname or lastname
          string = "#{string} [#{fullname}]"
        end
      else
        string = fullname
      end
      string
    end

    def fullname
      "#{firstname} #{lastname}"
    end

    def taxon
      taxonomy.root.children.where( :name => nickname ).first
    end

    def visible?
      visible
    end

    def permalink_prefix
      [firstname, lastname, company_name].compact.join('-').to_url
    end

    def to_param
      permalink.present? ? permalink.to_s.to_url : permalink_prefix.to_url
    end

    private


    def slug_candidates
      [
        :firstname,
        [:firstname, :lastname],
        [:firstname, :lastname, :company],
        [:firstname, :lastname, :company, ],
      ]
    end

    def taxonomy
      Spree::Taxonomy.find_or_create_by_name(TAXONOMY)
    end

    def set_nickname_as_taxon

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
