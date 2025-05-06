Rails.application.routes.draw do
  resources :measurements, path_names: {new: '/new(/:scope)'},
    constraints: {scope: /children|subtree/}, defaults: {scope: nil} do

    get 'discard/:id', on: :new, action: :discard, as: :discard
  end

  resources :quantities, except: [:show], path_names: {new: '(/:id)/new'} do
    member { post :reparent }
  end

  resources :units, except: [:show], path_names: {new: '(/:id)/new'} do
    member { post :rebase }
  end

  namespace :default do
    resources :units, only: [:index, :destroy] do
      member { post :import, :export }
      #collection { post :import_all }
    end
  end

  devise_for :users, path: '', path_names: {registration: 'profile'},
    controllers: {registrations: :registrations}
  resources :users, only: [:index, :show, :update] do
    member { get :disguise }
    collection { get :revert }
  end

  unauthenticated do
    as :user do
      root to: redirect('/sign_in')
    end
  end
  root to: redirect('/units'), as: :user_root

  direct(:source_code) { 'https://gitea.michalczyk.pro/fixin.me/fixin.me' }
  direct(:issue_tracker) { 'https://gitea.michalczyk.pro/fixin.me/fixin.me/issues' }
end
