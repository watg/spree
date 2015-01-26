Spree::Core::Engine.add_routes do

  root :to => 'home#index'
  get '/admin', :to => 'admin/orders#index', :as => :admin

  namespace :admin do
    get '/search/users', to: "search#users", as: :search_users

    get '/products_overview', :to => 'products_overview#index'
    post '/products_overview', :to => 'products_overview#update'

    resources :assembly_definitions do
      member do
        get :available_supply_products
      end

      resources :parts, :controller => 'assembly_definition_parts' do
        collection do
          post :update_positions
        end
      end

      resources :images, :controller => 'assembly_definition_images' do
        collection do
          post :s3_callback
          post :update_positions
        end
      end
    end

    resources :assembly_definition_parts do
      member do
        get :available_parts
      end
    end

    resources :gift_cards

    resources :suites do
      member do
        post :s3_callback
      end

      resources :tabs, controller: "suite_tabs" do
        member do
          post :s3_callback
        end
      end
    end

    resources :product_groups

    resources :suppliers

    resources :promotions do
      resources :promotion_rules
      resources :promotion_actions
    end

    resources :targets

    resources :promotion_categories, except: [:show]

    resources :zones

    resources :countries do
      resources :states
    end
    resources :states
    resources :tax_categories

    resources :products do

      resources :prices, :only => [:index, :create]
      resources :personalisations do
        collection do
          post :update_all
        end
      end

      resources :product_properties do
        collection do
          post :update_positions
        end
      end
      resources :images do
        collection do
          post :s3_callback
          post :update_positions
        end
      end
      member do
        get :clone
        get :stock
        get :create_assembly_definition
      end
      resources :variants do
        member do
          post :create_sku
        end
        collection do
          post :update_positions
        end
      end
      resources :variants_including_master,   only: [:update]
    end

    get '/variants/search', to: "variants#search", as: :search_variants

    resources :variants do
      resources :images, controller: "variant_images" do
        collection do
          post :s3_callback
          post :update_positions
        end
      end
    end


    resources :option_types do
      collection do
        post :update_positions
        post :update_values_positions
      end
    end

    delete '/option_values/:id', to: "option_values#destroy", as: :option_value

    resources :properties do
      collection do
        get :filtered
      end
    end

    delete '/product_properties/:id', to: "product_properties#destroy", as: :product_property

    resources :prototypes do
      member do
        get :select
      end

      collection do
        get :available
      end
    end

    resources :waiting_orders do
      collection do
        put :invoices
        put :image_stickers
      end
      member do
        post :create_and_allocate_consignment
      end
    end

    resources :print_jobs, :only => [:index, :show]

    resources :shipping_manifests

     resources :orders, except: [:show] do
      member do
        get :cart
        post :internal
        post :important
        post :refresh
        post :gift_card_reissue
        post :resend
        get :open_adjustments
        get :close_adjustments
        put :approve
        put :cancel
        put :resume
      end

      resource :customer, controller: "orders/customer_details"
      resources :customer_returns, only: [:index, :new, :edit, :create, :update] do
        member do
          put :refund
        end
      end

      resources :adjustments
      resources :line_items
      resources :return_authorizations do
        member do
          put :fire
        end
      end
      resources :payments do
        member do
          put :fire
        end

        resources :log_entries
        resources :refunds, only: [:new, :create, :edit, :update]
      end

      resources :holds, :controller => "orders/holds"

      resources :reimbursements, only: [:create, :show, :edit, :update] do
        member do
          post :perform
        end
      end
    end

    resource :general_settings do
      collection do
        post :dismiss_alert
        post :clear_cache
      end
    end

    resources :return_items, only: [:update]

    resources :taxonomies do
      collection do
        post :update_positions
      end
      member do
        get :get_children
      end
      resources :taxons
    end

    resources :taxons, only: [:index, :show] do
      collection do
        get :search
      end
    end

    resources :reports, :only => [:index] do
      collection do
        get '/download/:name/:id' => 'reports#download', :as => 'download'
        get '/:name' => 'reports#report', :as => 'report_name'
        get '/:name/:id' => 'reports#refresh', :as => 'refresh'
        post '/:name' => 'reports#create', :as => 'create'
      end
    end

    resources :reimbursement_types, only: [:index]
    resources :refund_reasons, except: [:show, :destroy]
    resources :return_authorization_reasons, except: [:show, :destroy]

    resources :shipping_methods
    resources :shipping_categories
    resources :stock_transfers, only: [:index, :show, :new, :create]
    resources :stock_locations do
      resources :stock_movements, except: [:edit, :update, :destroy]
      collection do
        post :transfer_stock
      end
    end

    resources :stock_items, only: [:create, :update, :destroy]
    resources :tax_rates

    resources :trackers
    resources :payment_methods
    resource :mail_method, :only => [:edit, :update] do
      post :testmail, :on => :collection
    end

    resources :users do
      member do
        get :orders
        get :items
        get :addresses
        put :addresses
      end
    end

  end # end admin namespace

end
