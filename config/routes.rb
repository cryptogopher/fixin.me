Rails.application.routes.draw do
  devise_for :users, path: '', path_names: {registration: 'register'}

  resources :users

  root "users#index"
end
