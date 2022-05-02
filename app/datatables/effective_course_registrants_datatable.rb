# Used on the Course Registrations courses step

class EffectiveCourseRegistrantsDatatable < Effective::Datatable
  datatable do
    col :learndash_course, label: 'Title'
    col :owner, label: 'Registrant', action: false
    col :price, as: :price
  end

  collection do
    scope = Effective::CourseRegistrant.deep.all

    if attributes[:learndash_course_id].present?
      scope = scope.where(learndash_course_id: attributes[:learndash_course_id])
    end

    if attributes[:course_registration_id].present?
      scope = scope.where(course_registration_id: attributes[:course_registration_id])
    end

    scope
  end

end
