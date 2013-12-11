Spree::Core::Engine.add_routes do

  # root :to => 'home#index'

  resources :products

  get '/locale/set', :to => 'locale#set'

  # two routes added from spree auth devise due to override below
  get '/checkout/registration' => 'checkout#registration', :as => :checkout_registration
  put '/checkout/registration' => 'checkout#update_registration', :as => :update_checkout_registration

  # non-restful checkout stuff

  patch '/checkout/update/:state', :to => 'checkout#update', :as => :update_checkout
  get '/checkout/:state', :to => 'checkout#edit', :as => :checkout_state
  get '/checkout', :to => 'checkout#edit' , :as => :checkout

  populate_redirect = redirect do |params, request|
    request.flash[:error] = Spree.t(:populate_get_error)
    request.referer || '/cart'
  end

  get '/orders/populate', :to => populate_redirect
  get '/orders/:id/token/:token' => 'orders#show', :as => :token_order

  resources :orders, :except => [:new, :create] do
    post :populate, :on => :collection
  end

  get '/cart', :to => 'orders#edit', :as => :cart
  patch '/cart', :to => 'orders#update', :as => :update_cart
  put '/cart/empty', :to => 'orders#empty', :as => :empty_cart

  # route globbing for pretty nested taxon and product paths
  get '/t/*id', :to => 'taxons#show', :as => :nested_taxons
  get '/t', :to => 'home#index'

  get '/unauthorized', :to => 'home#unauthorized', :as => :unauthorized
  get '/content/cvv', :to => 'content#cvv', :as => :cvv
  get '/content/*path', :to => 'content#show', :as => :content

  get '/items/:id(/:tab)(/*rest)', :to => 'product_pages#show', :as => :product_page


  # Top-level navigation to static pages
  get 'women', :to => 'navigation#product_top_women'
  get 'men', :to => 'navigation#product_top_men'
  get 'kids', :to => 'navigation#product_top_kids'
  get 'whats-new', :to => 'navigation#product_top_new'
  get 'gifts', :to => 'navigation#product_top_gifts'
  get 'knitting', :to => 'navigation#product_top_knitting'

  get '/knitwear/*id', :to => 'index_pages#show', :as => :index_page
  
end
