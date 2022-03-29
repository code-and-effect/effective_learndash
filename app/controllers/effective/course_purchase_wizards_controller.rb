module Effective
  class CoursePurchaseWizardsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)

    include Effective::WizardController

    resource_scope -> {
      learndash_course = Effective::LearndashCourse.find(params[:learndash_course_id])
      EffectiveLearndash.CoursePurchaseWizard.deep.where(owner: current_user, learndash_course: learndash_course)
    }

  end
end
