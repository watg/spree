Spree::Core::Engine.add_routes do

  namespace :admin do
    resources :users do
      member do
        put :generate_api_key
        put :clear_api_key
      end
    end
  end

  # delete once the provider api points are changed
  scope path: 'shop' do
    namespace :api, :defaults => { :format => 'json' } do
      get 'olapic' => 'olapic#index'
      get 'pinterest' => 'pinterest#show', as: :old_pinterest
    end
  end

  namespace :api, :defaults => { :format => 'json' } do
    get 'pinterest' => 'pinterest#show', :as => 'pinterest'

    resources :olapic, :only => [:index]
    get 'assembly_definition_parts/:id/variants' => 'assembly_definition_parts#variants', :as => 'assembly_definition_part_variants'
    get 'assembly_definitions/:id/out_of_stock_variants' => 'assembly_definitions#out_of_stock_variants', :as => 'assembly_definitions_variant_out_of_stock'
    get 'assembly_definitions/:id/out_of_stock_option_values' => 'assembly_definitions#out_of_stock_option_values', :as => 'assembly_definitions_option_values_out_of_stock'

    resources :tags
    resources :targets

    resources :promotions, only: [:show]
    resources :products do
      resources :images
      resources :variants
      resources :product_properties
    end
    resources :product_groups, :only => [:index]

    resources :suite, :only => [:index]

    concern  :order_routes do
      member do
        put :cancel
        put :empty
        put :apply_coupon_code
      end

      resources :line_items
      resources :payments do
        member do
          put :authorize
          put :capture
          put :purchase
          put :void
          put :credit
        end
      end

      resources :addresses, only: [:show, :update]

      resources :return_authorizations do
        member do
          put :add
          put :cancel
          put :receive
        end
      end
    end

    resources :checkouts, only: [:update], concerns: :order_routes do
      member do
        put :next
        put :advance
      end
    end

    resources :variants, only: [:index, :show] do
      resources :images
    end

    resources :option_types do
      resources :option_values
    end

    get '/orders/mine', to: 'orders#mine', as: 'my_orders'
    get "/orders/current", to: "orders#current", to: "orders#current", as: "current_order"

    resources :orders, concerns: :order_routes

    resources :zones
    resources :countries, only: [:index, :show] do
      resources :states, only: [:index, :show]
    end

    resources :shipments, only: [:create, :update] do
      collection do
        post 'transfer_to_location'
        post 'transfer_to_shipment'
        get :mine
      end

      member do
        put :ready
        put :ship
        put :add
        put :remove
        put :add_by_line_item
        put :remove_by_line_item
      end
    end
    resources :states, only: [:index, :show]

    resources :taxonomies do
      member do
        get :jstree
      end
      resources :taxons do
        member do
          get :jstree
        end
      end
    end

    resources :taxons, only: [:index]

    resources :inventory_units, only: [:show, :update]

    resources :users do
      resources :credit_cards, only: [:index]
    end

    resources :properties
    resources :stock_locations do
      resources :stock_movements
      resources :stock_items
    end

    resources :stores

    get '/config/money', to: 'config#money'
    get '/config', to: 'config#show'

    put '/classifications', to: 'classifications#update', as: :classifications
    #get '/taxons/products', to: 'taxons#products', as: :taxon_products
    get '/taxons/suites', :to => 'taxons#suites', :as => :taxon_suites
  end
end
