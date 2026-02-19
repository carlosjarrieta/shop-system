Rails.application.routes.draw do
  resources :customers, only: [:show]
end
