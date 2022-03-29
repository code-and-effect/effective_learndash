module Effective
  class LearndashCoursesController < ApplicationController
    include Effective::CrudController

    resource_scope -> {
      unpublished = EffectiveResources.authorized?(self, :admin, :effective_learndash)
      Effective::LearndashCourse.learndash_courses(user: current_user, unpublished: unpublished)
    }

    def show
      @learndash_course = resource_scope.find(params[:id])

      if @learndash_course.respond_to?(:roles_permit?)
        raise Effective::AccessDenied.new('Access Denied', :show, @learndash_course) unless @learndash_course.roles_permit?(current_user)
      end

      EffectiveResources.authorize!(self, :show, @learndash_course)

      if EffectiveResources.authorized?(self, :admin, :effective_learndash)
        flash.now[:warning] = [
          'Hi Admin!',
          ('You are viewing a hidden course.' if @learndash_course.draft?),
          'Click here to',
          ("<a href='#{effective_learndash.edit_admin_learndash_course_path(@learndash_course)}' class='alert-link'>edit learndash course settings</a>.")
        ].compact.join(' ')
      end

      @page_title ||= @learndash_course.to_s
    end

  end
end
