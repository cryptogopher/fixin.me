Rails.application.routes.draw do
  devise_for :users, path: '', path_names: {registration: 'profile'},
    controllers: {registrations: :registrations}

  resources :users, only: [:index]

  devise_scope :user do
    root to: "devise/sessions#new"
  end
end
