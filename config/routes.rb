# frozen_string_literal: true

Rails.application.routes.draw do
  mount EffectiveLearndash::Engine => '/', as: 'effective_learndash'
end

EffectiveLearndash::Engine.routes.draw do
  namespace :admin do
    get '/learndash', to: 'learndash#index', as: :learndash

    resources :learndash_users, except: [:edit, :update, :destroy]
    resources :learndash_progresses, except: [:show, :destroy]

    resources :learndash_courses, only: [:index, :show] do
      get :sync, on: :collection
    end

  end

end
