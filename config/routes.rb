# frozen_string_literal: true

Rails.application.routes.draw do
  mount EffectiveLearndash::Engine => '/', as: 'effective_learndash'
end

EffectiveLearndash::Engine.routes.draw do
  namespace :admin do
    get '/learndash', to: 'learndash#index', as: :learndash

    resources :learndash_users, only: [:index, :show, :new, :create, :update] do
      post :refresh, on: :member
    end

    resources :learndash_enrollments, only: [:index, :new, :create, :update] do
      post :refresh, on: :member
    end

    resources :learndash_courses, only: [:index, :show, :update] do
      get :refresh, on: :collection
    end

  end

end
