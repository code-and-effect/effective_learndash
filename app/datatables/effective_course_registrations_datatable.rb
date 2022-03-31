# Dashboard Course Registrations
class EffectiveCourseRegistrationsDatatable < Effective::Datatable
  datatable do
    order :created_at

    col :token, visible: false
    col :created_at, visible: false

    col :learndash_course, label: 'Title', search: :string do |registration|
      registration.learndash_course.to_s
    end

    col(:submitted_at, label: 'Registered on') do |registration|
      registration.submitted_at&.strftime('%F') || 'Incomplete'
    end

    col :owner, visible: false, search: :string
    col :status, visible: false
    col :orders, action: :show, visible: false, search: :string

    actions_col(actions: []) do |registration|
      if registration.draft?
        dropdown_link_to('Continue', effective_learndash.learndash_course_course_registration_build_path(registration.learndash_course, registration, registration.next_step), 'data-turbolinks' => false)
        dropdown_link_to('Delete', effective_learndash.learndash_course_course_registration_path(registration.learndash_course, registration), 'data-confirm': "Really delete #{registration}?", 'data-method': :delete)
      else
        dropdown_link_to('Show', effective_learndash.learndash_course_course_registration_path(registration.learndash_course, registration))
      end
    end
  end

  collection do
    EffectiveLearndash.CourseRegistration.deep.where(owner: current_user)
  end

end
