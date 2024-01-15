Rails.application.routes.draw do
  devise_for :users, path: '', path_names: {registration: 'profile'},
    controllers: {registrations: :registrations}

  resources :units, except: [:show]

  resources :users, only: [:index, :show, :update] do
    member do
      get :disguise
    end
    collection do
      get :revert
    end
  end

  devise_scope :user do
    root to: "devise/sessions#new"
  end
end
