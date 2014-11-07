Conquest::Application.routes.draw do
  root "pages#home"
  get "home", to: "pages#home", as: "home"
  get "inside", to: "pages#inside", as: "inside"
  get "/contact", to: "pages#contact", as: "contact"
  post "/emailconfirmation", to: "pages#email", as: "email_confirmation"


  devise_for :users, :controllers => { omniauth_callbacks: 'omniauth_callbacks' }

  namespace :admin do
    root "base#index"
    resources :users

  end

  match '/users/:id/finish_signup' => 'users#finish_signup', via: [:get, :patch], :as => :finish_signup

end
