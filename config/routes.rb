Rails.application.routes.draw do
  devise_for :users

  root to: "static#dashboard"
  get 'people/:id', to: 'static#person', as: 'person'

  resources :expenses, only: [:create, :destroy]
  resources :settlements, only: [:create]
end
