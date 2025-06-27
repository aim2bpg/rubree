Rails.application.routes.draw do
  root "regular_expressions#index"

  resources :regular_expressions, only: %i[index create]
  get "*path", to: "regular_expressions#index", constraints: ->(req) { !req.xhr? && req.format.html? }
end
