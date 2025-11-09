Rails.application.routes.draw do
  root "regular_expressions#index"

  resources :regular_expressions, only: %i[index create]
  get "regular_expressions/examples", to: "regular_expressions#examples", as: :regular_expression_examples
  get "*path", to: "regular_expressions#index", constraints: ->(req) { !req.xhr? && req.format.html? }
end
