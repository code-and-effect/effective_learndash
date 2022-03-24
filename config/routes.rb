# frozen_string_literal: true

Rails.application.routes.draw do
  mount EffectiveLearndash::Engine => '/', as: 'effective_learndash'
end

EffectiveLearndash::Engine.routes.draw do
  namespace :admin do
    get '/learndash', to: 'learndash#index', as: :learndash

    resources :learndash_users, only: [:index, :show, :new, :create]

    resources :learndash_enrollments, only: [:index, :new, :create, :update] do
      post :sync, on: :member
    end

    resources :learndash_courses, only: [:index] do
      get :sync, on: :collection
    end

  end

end
