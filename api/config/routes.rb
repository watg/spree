Spree::Core::Engine.add_routes do
  namespace :admin do
    resources :users do
      member do
        put :generate_api_key
        put :clear_api_key
      end
    end
  end

  namespace :api, :defaults => { :format => 'json' } do
    get 'pinterest' => 'pinterest#show', :as => 'pinterest'

    resources :products do
      resources :variants
      resources :product_properties
    end

    resources :images
    resources :checkouts do
      member do
        put :next
        put :advance
      end
    end

    resources :variants, :only => [:index]

    resources :tags

    resources :option_types do
      resources :option_values
    end

    resources :orders do
      resources :addresses, :only => [:show, :update]

      resources :return_authorizations do
        member do
          put :add
          put :cancel
          put :receive
        end
      end
      member do
        put :cancel
        put :empty
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

      resources :shipments, :only => [:create, :update] do
        member do
          put :ready
          put :ship
          put :add
          put :remove
        end
      end
    end

    resources :zones
    resources :countries, :only => [:index, :show]
    resources :states,    :only => [:index, :show]

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
    resources :taxons, :only => [:index]
    resources :inventory_units, :only => [:show, :update]
    resources :users
    resources :properties
    resources :stock_locations do
      resources :stock_movements
      resources :stock_items
    end

    get '/config/money', :to => 'config#money'
    get '/config', :to => 'config#show'
  end
end
