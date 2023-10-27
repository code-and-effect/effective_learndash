# Dashboard Available Courses
class EffectiveLearndashAvailableCoursesDatatable < Effective::Datatable
  datatable do
    order :title
    col :id, visible: false

    col :title do |learndash_course|
      learndash_course.to_s
    end

    actions_col show: false do |learndash_course|
      if learndash_course.can_register?
        dropdown_link_to('Register', effective_learndash.new_learndash_course_course_registration_path(learndash_course))
      end
    end
  end

  collection do
    enrolled = Effective::LearndashEnrollment.where(learndash_user: current_user.learndash_user).select(:learndash_course_id)
    courses = Effective::LearndashCourse.deep.registerable.learndash_courses(user: current_user)

    courses.where.not(id: enrolled)
  end

end
