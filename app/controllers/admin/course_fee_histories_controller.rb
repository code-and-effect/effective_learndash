module Admin
  class CourseFeeHistoriesController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_learndash) }

    include Effective::CrudController

    # Inline datatable create/update/destroy do an in-place row swap and never re-render the
    # price-timeline warnings shown on the course page. When triggered from an inline datatable,
    # redirect back so the whole page reloads and the warnings recompute.
    on(:save,    redirect: -> { :back if params[:_datatable_id].present? })
    on(:destroy, redirect: -> { :back if params[:_datatable_id].present? })

    # Duplicating closes the current prices at year-end and opens next year's copy.
    on(:duplicate, redirect: -> { :back },
      success: -> { "Copied #{resource.learndash_course}'s prices forward — set next year's prices on the new history." })

    def permitted_params
      params.require(:effective_course_fee_history).permit!
    end

  end
end
