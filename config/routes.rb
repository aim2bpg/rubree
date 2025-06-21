Rails.application.routes.draw do
  root "regular_expressions#index"

  resources :regular_expressions, only: %i[index create]
end
