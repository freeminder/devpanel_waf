Rails.application.routes.draw do
  # root 'rules#index'

  devise_for :users, controllers: {registrations: 'registrations'}
  resources :webacls, :rules, :ipsets

end
