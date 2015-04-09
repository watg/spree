class IndexedSearch < ActiveRecord::Base
  belongs_to :suite, class_name: "Spree::Suite", foreign_key: :suite_id
  belongs_to :taxon, class_name: "Spree::Taxon", foreign_key: :taxon_id

  def self.rebuild
    connection = ActiveRecord::Base.connection
    connection.execute("REFRESH MATERIALIZED VIEW indexed_searches")
  end

  private

  def read_only?
    true
  end
end