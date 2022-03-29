# frozen_string_literal: true

# This is a purchasable object and wizard that will create learndash enrollments
# An admin can also just create learndash enrollments without a learndash access

module Effective
  class CourseRegistrant < ActiveRecord::Base
    acts_as_purchasable

    log_changes(to: :learndash_course) if respond_to?(:log_changes)

    # The learndash course containing all the pricing and unique info about this course purchase
    belongs_to :learndash_course

    # Every course is charged to a owner
    belongs_to :owner, polymorphic: true

    # As checked out through the learndash course purchase wizard
    belongs_to :course_registration, polymorphic: true

    effective_resource do
      # Acts as Purchasable
      price             :integer
      qb_item_name      :string
      tax_exempt        :boolean

      timestamps
    end

    scope :sorted, -> { order(:id) }
    scope :deep, -> { includes(:learndash_course, :owner, :course_registration) }

    before_validation(if: -> { course_registration.present? }) do
      self.learndash_course ||= course_registration.learndash_course
      self.owner ||= course_registration.owner
    end

    before_validation(if: -> { learndash_course.present? }) do
      self.price ||= learndash_course.price
    end

    def to_s
      persisted? ? title : 'course purchase'
    end

    def title
      "#{learndash_course} - #{owner}"
    end

    def tax_exempt
      learndash_course.tax_exempt
    end

    def qb_item_name
      learndash_course.qb_item_name
    end

  end
end
