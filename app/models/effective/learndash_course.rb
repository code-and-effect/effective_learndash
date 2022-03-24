module Effective
  class LearndashCourse < ActiveRecord::Base
    effective_resource do

      # This user the wordpress credentials
      course_id                 :integer
      status                    :string
      title                     :string

      timestamps
    end

    scope :deep, -> { all }
    scope :sorted, -> { order(:id) }

    validates :course_id, presence: true
    validates :status, presence: true
    validates :title, presence: true

    def to_s
      title.presence || 'learndash course'
    end

    # Syncs all courses
    def self.sync!
      api = EffectiveLearndash.api

      courses = all()

      api.courses.each do |data|
        course = courses.find { |course| course.course_id == data[:id] } || new()

        course.update!(
          course_id: data[:id],
          title: data.dig(:title, :rendered),
          status: data[:status],
          link: data[:link]
        )

        course
      end

      true
    end

  end
end
