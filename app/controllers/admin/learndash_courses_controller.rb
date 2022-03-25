module Admin
  class LearndashCoursesController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_learndash) }

    include Effective::CrudController

    def refresh
      resource_scope.refresh!
      flash[:success] = "Successfully refreshed Courses from Learndash"
      redirect_to effective_learndash.admin_learndash_courses_path
    end

  end
end
