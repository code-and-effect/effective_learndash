module Admin
  class LearndashController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_learndash) }

    include Effective::CrudController

    # /admin/learndash
    def index
      @page_title = 'Learndash'
    end

  end
end
