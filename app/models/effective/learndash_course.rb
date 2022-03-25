module Effective
  class LearndashCourse < ActiveRecord::Base
    has_many :learndash_enrollments
    has_many :learndash_users, through: :learndash_enrollments

    effective_resource do
      # This user the wordpress credentials
      course_id                 :integer
      status                    :string
      title                     :string

      timestamps
    end

    scope :deep, -> { all }
    scope :sorted, -> { order(:title) }

    validates :course_id, presence: true
    validates :status, presence: true
    validates :title, presence: true

    # Syncs all courses
    def self.refresh!
      courses = all()

      EffectiveLearndash.api.courses.each do |data|
        course = courses.find { |course| course.course_id == data[:id] } || new()
        course.update!(course_id: data[:id], title: data.dig(:title, :rendered), status: data[:status], link: data[:link])
      end

      true
    end

    def to_s
      title.presence || 'learndash course'
    end

  end
end
