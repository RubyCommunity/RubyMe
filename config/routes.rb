Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".
  # require 'sidekiq/web'
  # mount Sidekiq::Web => '/sidekiq'

  mount RuCaptcha::Engine => "/rucaptcha"
  # scope "(:locale)", :locale => /en|zh|th|en-AU|en-US|en-UK|zh-TW|es/ do
  mount Ckeditor::Engine => '/ckeditor'
  get 'update_captcha', to: 'simple_captcha#update_captcha'
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  devise_for :users, path: 'user', controllers: {registrations: 'users/registrations', sessions: 'users/sessions'
  }
  devise_scope :user do
    post '/admin/is_uid_exist', to: 'users/registrations#is_uid_exist'
  end

  require 'sidekiq/web'
  constraint = lambda { |request|
    # config.default_scope in file devise.rb effects request.env['warden'].user
    request.env["warden"].authenticate? and request.env['warden'].user.instance_of?(AdminUser)
  }
  constraints constraint do
    mount Sidekiq::Web => 'system/sidekiq' # only for system user
  end

  # 定义登陆后的访问
  namespace :admin, path: '/admin' do
    root 'home#index'

    get '/profile', to: 'home#profile'
    post '/update_profile', to: 'home#update_profile'

    resources :posts

    resources :replies, only: [:destroy, :index] do
      member do
        post 'hide', to: 'replies#hide'
        post 'restore', to: 'replies#restore'
      end
    end

    resources :messages, only: [:show, :destroy, :index] do
      member do
        post 'mark_as_read', to: 'messages#mark_as_read'
      end
    end

    resources :codes

    resources :blogs

    resources :categories, except: [:new]
  end

  get '/search' => 'search#index', as: 'search'

  namespace :frontend, path: '/' do
    root 'home#index'
    get '/about_us', to: 'home#about_us'
    resources :blogs, only: [:show, :index]

    resources :posts, only: [:show] do
      resources :replies, only: [:create]
    end

    scope ':uid' do
      get '/', to: 'users#show'
      get '/profile', to: 'users#profile'

      resources :categories, only: [:show]

      resources :codes, only: [:show, :index]
    end

  end
  # end
end
