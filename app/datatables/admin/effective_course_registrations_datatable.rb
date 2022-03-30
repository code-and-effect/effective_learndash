module Admin
  class EffectiveCourseRegistrationsDatatable < Effective::Datatable
    datatable do
      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :token, visible: false

      col :created_at, label: 'Created', visible: false
      col :updated_at, label: 'Updated', visible: false
      col :submitted_at, label: 'Submitted', visible: false, as: :date

      col :learndash_course
      col :owner

      col :course_registrants, search: :string, visible: false
      col :orders, label: 'Order'

      actions_col
    end

    collection do
      scope = EffectiveLearndash.CourseRegistration.all.deep.done
    end

  end
end
