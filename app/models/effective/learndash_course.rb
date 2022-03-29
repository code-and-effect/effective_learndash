module Effective
  class LearndashCourse < ActiveRecord::Base
    has_many :learndash_enrollments
    has_many :learndash_users, through: :learndash_enrollments

    log_changes if respond_to?(:log_changes)

    # rich_text_body - Used by the select step
    has_many_rich_texts

    # rich_text_body

    # rich_text_all_steps_content
    # rich_text_start_content
    # rich_text_select_content
    # rich_text_select_content

    effective_resource do
      # This user the wordpress credentials
      course_id             :integer
      title                 :string
      status                :string

      # For course purchases
      can_purchase          :boolean

      # Pricing
      regular_price         :integer
      member_price          :integer

      qb_item_name          :string
      tax_exempt            :boolean

      timestamps
    end

    scope :deep, -> { all }
    scope :sorted, -> { order(:title) }

    scope :can_purchase, -> { where(can_purchase: true) }

    validates :course_id, presence: true
    validates :status, presence: true
    validates :title, presence: true

    with_options(if: -> { can_purchase? }) do
      validates :regular_price, presence: true
      validates :member_price, presence: true
    end

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
