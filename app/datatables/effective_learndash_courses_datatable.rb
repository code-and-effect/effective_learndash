# Dashboard Courses
class EffectiveLearndashCoursesDatatable < Effective::Datatable
  filters do
    # Registerable should be first here, so when displayed as a simple datatable on the dashboard they only see registerable courses
    scope :registerable
    scope :all
  end

  datatable do
    order :title
    col :id, visible: false

    col :title, label: 'Title' do |learndash_course|
      link_to(learndash_course.to_s, effective_learndash.learndash_course_path(learndash_course))
    end

    actions_col show: false do |learndash_course|
      if learndash_course.can_register?
        dropdown_link_to('Register', effective_learndash.new_learndash_course_course_registration_path(learndash_course))
      end
    end
  end

  collection do
    Effective::LearndashCourse.deep.learndash_courses(user: current_user)
  end

end
