module Admin
  class CoursePurchasesController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_learndash) }

    include Effective::CrudController
  end
end
