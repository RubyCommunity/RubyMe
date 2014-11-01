Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  devise_for :users, path: 'admin'

  namespace :frontend, path: '/' do
    root 'home#index'
    resources :users
  end

  namespace :admin, path: '/admin' do
    root 'home#index'
  end

end
