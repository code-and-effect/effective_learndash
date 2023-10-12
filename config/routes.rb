# frozen_string_literal: true

Rails.application.routes.draw do
  mount EffectiveLearndash::Engine => '/', as: 'effective_learndash'
end

EffectiveLearndash::Engine.routes.draw do
  # Public routes
  scope module: 'effective' do
    resources :learndash_courses, only: [:index] do
      resources :course_registrations, only: [:new, :show, :destroy] do
        resources :build, controller: :course_registrations, only: [:show, :update]
      end
    end
  end

  namespace :admin do
    get '/learndash', to: 'learndash#index', as: :learndash

    resources :learndash_users, except: [:edit, :destroy] do
      post :refresh, on: :member
    end

    resources :learndash_enrollments, only: [:index, :new, :create, :update] do
      post :refresh, on: :member
      post :mark_as_finished, on: :member
      post :unfinish, on: :member
    end

    resources :learndash_courses, only: [:index, :edit, :update] do
      get :refresh, on: :collection
    end

    resources :course_registrants, only: [:index]
    resources :course_registrations, only: [:index, :show]
  end
end
