module Admin
  class CourseFeeHistoriesDatatable < Effective::Datatable
    datatable do
      order :start_on, :desc

      col :id, visible: false
      col :created_at, visible: false
      col :updated_at, visible: false

      col :learndash_course, search: Effective::LearndashCourse.sorted

      col :start_on
      col :end_on, label: 'End on<br>(blank = current)'

      col :regular_fee, as: :price
      col :member_fee, as: :price

      actions_col
    end

    collection do
      Effective::CourseFeeHistory.deep.all
    end

  end
end
