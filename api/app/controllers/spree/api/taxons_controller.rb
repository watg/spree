module Spree
  module Api
    class TaxonsController < Spree::Api::BaseController
      def index
        if taxonomy
          @taxons = taxonomy.root.children
        else
          if params[:ids]
            @taxons = Spree::Taxon.accessible_by(current_ability, :read).where(id: params[:ids].split(','))
          else
            @taxons = Spree::Taxon.accessible_by(current_ability, :read).order(:taxonomy_id, :lft).ransack(params[:q]).result
          end
        end

        @taxons = @taxons.page(params[:page]).per(params[:per_page])
        respond_with(@taxons)
      end

      def show
        @taxon = taxon
        respond_with(@taxon)
      end

      def jstree
        show
      end

      def create
        authorize! :create, Taxon
        @taxon = Spree::Taxon.new(taxon_params)
        @taxon.taxonomy_id = params[:taxonomy_id]
        taxonomy = Spree::Taxonomy.find_by(id: params[:taxonomy_id])

        if taxonomy.nil?
          @taxon.errors[:taxonomy_id] = I18n.t(:invalid_taxonomy_id, scope: 'spree.api')
          invalid_resource!(@taxon) and return
        end

        @taxon.parent_id = taxonomy.root.id unless params[:taxon][:parent_id]

        if @taxon.save
          respond_with(@taxon, status: 201, default_template: :show)
        else
          invalid_resource!(@taxon)
        end
      end

      def update
        authorize! :update, taxon
        outcome = TaxonUpdateService.run(taxon: taxon, params: taxon_params)
        if outcome.valid?
          respond_with(taxon, status: 200, default_template: :show)
        else
          invalid_resource!(taxon)
        end
      end

      def destroy
        authorize! :destroy, taxon
        TaxonDestroyService.run(taxon: taxon)
        respond_with(taxon, status: 204)
      end

      def suites
        # Returns the suites sorted by their position with the classification
        # Products#index does not do the sorting.
        taxon = Spree::Taxon.find(params[:id])
        @suites = taxon.suites.includes(:image).ransack(params[:q]).result
        @suites = @suites.page(params[:page]).per(params[:per_page] || 500)
        render "spree/api/suites/index"
      end

      private

      # Delete this if nothing breaks ( 5/1/15 DD )
      #def update_params
      #  #{parent_id: params[:taxon][:parent_id], taxon_id: taxon.id, position: params[:taxon][:position]}
      #  hsh = params[:taxon]
      #  hsh[:taxon_id] = taxon.id
      #  {data: hsh}
      #end

        def taxonomy
          if params[:taxonomy_id].present?
            @taxonomy ||= Spree::Taxonomy.accessible_by(current_ability, :read).find(params[:taxonomy_id])
          end
        end

        def taxon
          @taxon ||= taxonomy.taxons.accessible_by(current_ability, :read).find(params[:id])
        end

        def taxon_params
          if params[:taxon] && !params[:taxon].empty?
            params.require(:taxon).permit(permitted_taxon_attributes)
          else
            {}
          end
        end
    end
  end
end
