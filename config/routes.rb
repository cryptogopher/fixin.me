Rails.application.routes.draw do
  devise_for :users, path: '', path_names: {registration: 'register'},
    controllers: {registrations: :registrations}

  resources :users

  root "users#index"
end
