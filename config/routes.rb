Rails.application.routes.draw do
  get "agendar", to: "bookings#new", as: :new_booking
  post "agendar", to: "bookings#create", as: :bookings
  get "agendar/confirmacao", to: "bookings#confirmation", as: :booking_confirmation
  if Rails.env.development? || Rails.env.test? || ENV["ADMIN_ACCESS_ENABLED"] == "true"
    get "login", to: "sessions#new", as: :login
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy", as: :logout
    get "admin/profile", to: "admin/profiles#show", as: :admin_profile
    get "admin/password/edit", to: "passwords#edit", as: :edit_password
    patch "admin/password", to: "passwords#update", as: :password
    root "admin/dashboard#index"
    namespace :admin do
      resources :users, except: :destroy do
        member do
          get :activation
          get :deactivation
          patch :activate
          patch :deactivate
          get :password_reset
          patch :password_reset, action: :reset_password
        end
      end
      resources :audit_events, only: %i[index show]
      root "dashboard#index"
      get "dashboard/refresh", to: "dashboard#refresh", as: :dashboard_refresh
      resources :slot_blocks, only: %i[index create destroy] do
        member { get :unblocking }
        collection do
          post :review_unblock
          post :bulk_unblock
        end
      end
      resources :bookings, only: %i[index show] do
        collection { get :export, defaults: { format: :xlsx } }
        member do
          get :receipt
          get :edit, to: "booking_changes#edit"
          get :cancellation, to: "booking_changes#cancellation"
          patch :reschedule, to: "booking_changes#reschedule"
          patch :cancel, to: "booking_changes#cancel"
          get :confirm_checkin
          get :confirm_release
          patch :checkin
          patch :release
        end
      end
    end
  else
    root "home#index"
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "ready" => "readiness#show", as: :readiness
end
