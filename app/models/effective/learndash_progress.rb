module Effective
  class LearndashProgress < ActiveRecord::Base

    belongs_to :owner, polymorphic: true

    belongs_to :learndash_course, class_name: 'Effective::LearndashCourse'
    belongs_to :learndash_user, class_name: 'Effective::LearndashUser'

    effective_resource do
      progress_status     :string

      last_step           :integer
      steps_completed     :integer
      steps_total         :integer

      date_started        :datetime
      date_completed      :datetime

      timestamps
    end

    scope :deep, -> { all }
    scope :sorted, -> { order(:id) }

    def to_s
      title.presence || 'learndash course'
    end

  end
end
