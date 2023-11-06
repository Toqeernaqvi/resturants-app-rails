require 'sidekiq/web'
Rails.application.routes.draw do
  mount ActionCable.server => '/cable'
  mount Ckeditor::Engine => '/ckeditor'
  authenticate do
    mount Sidekiq::Web => '/sidekiq'
  end
  root to: "admin/dashboard#index"
  devise_for :admin_users, ActiveAdmin::Devise.config
  devise_for :restaurant_admins, skip: :all
  devise_for :company_admins, skip: :all
  devise_for :company_users, skip: :all
  devise_for :company_managers, skip: :all
  devise_for :unsubsidized_users, skip: :all
  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      mount_devise_token_auth_for 'User', at: 'auth', controllers: {
        confirmations: 'api/v1/auth/confirmations',
        sessions:  'api/v1/auth/sessions',
        passwords: 'api/v1/auth/passwords',
        unlocks: 'api/v1/auth/unlocks'
      }
      namespace :dashboard do
        resources :meetings do
          collection do
            get :your_deliveries
            get :delivery_requests
            get :your_locations
            get :other_locations
          end
        end
      end
      resources :announcements, only: [:index]
      namespace :vendor do
        resources :shortened_urls, only: [:show]
        # get '/:id' => "shortened_urls#show"
        resources :restaurants do
          resources :menus, only: [:index, :update] do
            put :relate_fooditem
            post :fooditems
            post :dishsizes
          end
          collection do
            get :summary_excel
          end
          member do
            get :meetings
            get 'meetings/:meeting_id/orders', to: 'restaurants#orders'
            get 'meetings/:meeting_id/get_summary_pdf', to: 'restaurants#get_summary_pdf'
            # get 'meetings/:meeting_id/summary_excel', to: 'restaurants#summary_excel'
            get 'meetings/:meeting_id/get_labels', to: 'restaurants#get_labels'
            put 'meetings/:meeting_id/orders_status', to: 'restaurants#orders_status'
            # get :delivery_dates
            put :update_settings
            get :admins
          end
          resources :reports, only: [:index]
          resources :billings, only: [:index, :show]
          resources :invoices, only: [:index, :show, :update] do
            get :forward_invoice
            post :forwarded_invoice
          end
          collection do
            post :zendesk_support
            get :cuisines
            put :update_admin
          end
        end
        resources :drivers do
          collection do
            post :meeting_driver
          end
        end
        resources :schedules, only: [] do
          member do
            put 'acknowledge', to: 'restaurants#acknowledge_schedule'
          end
        end
        get '/freshdesk_logs', to: 'logs#freshdesk_logs'
      end
      resources :searches, only: [:index] do
        get :restaurants, on: :collection
      end
      resources :reports, only: [:index]
      get '/cuisines', to: 'cuisines#index'
      #get 'companies/addresses', to: 'companies#addresses'
      #get 'companies/fields', to: 'companies#custom_fields'
      get 'company', to: 'companies#index'
      #get 'companies/orders/show/:runningmenu_id/:address_id/:order_type/:ordered_at', to: 'orders#company_orders_show'
      # get 'companies/orders/show/:runningmenu_id/:address_id/:order_type/:ordered_at/:email', to: 'orders#company_orders_show'
      # post 'companies/orders/show/:runningmenu_id/:address_id/:order_type/:ordered_at/:email', to: 'orders#company_orders_show'
      # get 'checkrequests/:delivery_at/:type/:address_id', to: 'schedules#checkrequests'
      # get '/menu_change_request/:delivery_at/:type/:address_id', to: 'schedules#request_menu_change'
      # get 'meetings', to: 'schedules#meetings'
      #get 'all_schedules', to: 'schedules#all_schedules'
      # get 'pendingrequests', to: 'schedules#pendingrequests'
      get 'orders_ratings', to: 'orders#order_ratings'
      get 'restaurants_cuisines', to: 'cuisines#restaurants_cuisines'
      # post 'schedule_request/create', to: 'menus#create_schedule_request'
      # post 'stripe/connect', to: 'stripe#connect'
      get 'stripe/connect', to: 'stripe#connect'
      get 'stripe/login', to: 'stripe#login'
      get 'stripe/completion', to: 'stripe#completion'
      post 'referrals/send_invite', to: 'referrals#invite_referred'

      resources :companies, only: [:update] do
        collection do
          put :billing
          get :billings
          get :future_meeting
          get :fields
          get :addresses
          get :meetings
          get :childs
          get :send_invoice_email
        end
      end
      resources :menus, only: [] do
        collection do
          get :schedules
        end
      end
      resources :addresses, only: [] do
        get :menus
      end
      resources :orders, only: [:show, :update, :index] do
        member do
          get :fooditem
          post :rating
          get :restaurant
          get ':email', to: 'orders#show'
          delete :cancel
        end
        collection do
          post :clone
          get :cancelled
        end
      end

      resources :schedules, only: [:show, :update, :create] do
        member do
          get :orders
          get :notify_users
          delete :cancel
          get :recent
        end
        collection do
          get :cancelled
          get :delivery_dates
        end
      end

      # resources :schedule_requests, only: [:create, :update]
      # resources :schedules, only: [:index] do
      resources :schedules, only: [] do
        get 'active_orders', to: 'menus#orders'
        get 'buffet_orders', to: 'orders#buffet'
        # resources :addresses, only: [] do
        resources :menus, only: [:index] do
          get :dynamic_sections, on: :collection
        end
        # end
        resources :orders, only: [:create]

        resources :share_meetings do
          collection do
            post :by_token
            post :generate_token
            post :add_customer
          end
          get :resend_invite
        end
      end

      resources :childs do
        member do
          get :company_admins
          get :company_locations
        end
        collection do
          put :update_user
        end
      end

      resources :user_requests do
        member do
          get :send_invite
        end
      end
      resources :users, only: [:index, :destroy, :update] do
        member do
          post :send_invite
        end
        collection do
          get :profile
          put :profile
          post :invite
          put :invite
          post :send_vendor_invite
          get :search
        end
      end
      resources :fooditems, only: [] do
        resources :favorites, only: [:create] do
          delete "", to: 'favorites#destroy', on: :collection
        end
      end
    end
  end

  namespace :admin do
    resources :email_logs
    get 'schedules/:id/address/:address_id/acknowledge', to: 'acknowledges#acknowledge'
    get '/onfleet/webhook', to: 'webhooks#validate'
    get '/onfleet/webhook/driver_arrival', to: 'webhooks#validate'
    get '/onfleet/webhook/driver_eta', to: 'webhooks#validate'
    get '/onfleet/webhook/task_started', to: 'webhooks#validate'
    post '/onfleet/webhook', to: 'webhooks#receive'
    post '/onfleet/webhook/driver_arrival', to: 'webhooks#driver_arrival'
    post '/onfleet/webhook/driver_eta', to: 'webhooks#driver_eta'
    post '/onfleet/webhook/task_started', to: 'webhooks#task_started'
    get '/twilio/webhook', to: 'webhooks#sms_receive'
    get '/restaurants/twilio/webhook', to: 'webhooks#restaurants_sms'
    # post '/twilio_fax_status/webhook', to: 'webhooks#fax_status_callback'
    # post '/twilio_sms_status/webhook', to: 'webhooks#sms_status_callback'
    post '/freshdesk/webhook', to: 'webhooks#freshdesk_ticket_receive'
    get '/quickbooks_oauth/webhook', to: 'webhooks#quickbooks_oauth_callback'
    resources :restaurants do
      resources :addresses
      resources :gmenus do
        member do
          get :relate_gfooditems
          post :related_gfooditems
          get :relate_goptionsets
          post :related_goptionsets
        end
        collection do
          post :import
        end
      end
      resources :addresses do
        resources :menus do
          member do
            get :relate_fooditems
            post :related_fooditems
            get :relate_optionsets
            get :relate_dishsizes
            post :related_optionsets
            post :related_dishsizes
            get :fooditems_nutritions
            get :options_nutritions
          end
          collection do
            post :import
          end
        end
      end
    end
  end

  ActiveAdmin.routes(self)
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
