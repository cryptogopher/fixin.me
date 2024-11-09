Rails.application.routes.draw do
  devise_for :users, path: '', path_names: {registration: 'profile'},
    controllers: {registrations: :registrations}

  resources :units, except: [:show], path_names: {new: '(/:id)/new'} do
    member do
      post :rebase
    end
  end

  namespace :default do
    resources :units, only: :index
  end

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

  direct(:source_code) { "https://gitea.michalczyk.pro/fixin.me/fixin.me" }
  direct(:issue_tracker) { "https://gitea.michalczyk.pro/fixin.me/fixin.me/issues" }
end
