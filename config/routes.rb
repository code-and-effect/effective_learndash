# frozen_string_literal: true

Rails.application.routes.draw do
  mount EffectiveLearndash::Engine => '/', as: 'effective_learndash'
end

EffectiveLearndash::Engine.routes.draw do
  namespace :admin do
    get '/learndash', to: 'learndash#index', as: :learndash

    resources :learndash_users, only: [:index]
  end

end
