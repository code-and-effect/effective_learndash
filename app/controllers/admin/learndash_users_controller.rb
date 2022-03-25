module Admin
  class LearndashUsersController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_learndash) }

    include Effective::CrudController

    on :refresh, success: -> { "Successfully refreshed #{resource} and all course enrollments" }

  end
end
