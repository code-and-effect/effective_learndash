# Dashboard LearndashUsers
class EffectiveLearndashEnrollmentsDatatable < Effective::Datatable
  datatable do
    col :learndash_course
    col :progress_status

    col :last_step, visible: false
    col :steps_completed, visible: false
    col :steps_total, visible: false

    col :date_started, as: :date
    col :date_completed, as: :date

    actions_col(show: false) do |enrollment|
      if enrollment.not_started?
        dropdown_link_to('Start', EffectiveLearndash.learndash_url, target: '_blank')
      elsif enrollment.in_progress?
        dropdown_link_to('Continue', EffectiveLearndash.learndash_url, target: '_blank')
      else
        dropdown_link_to('Show', EffectiveLearndash.learndash_url, target: '_blank')
      end
    end

  end

  collection do
    Effective::LearndashEnrollment.deep.where(learndash_user: current_user.learndash_user)
  end

end
