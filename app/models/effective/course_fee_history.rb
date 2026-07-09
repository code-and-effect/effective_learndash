module Effective
  # A dated set of prices for a learndash course.
  #
  # Prices used to live in flat columns (regular_price, member_price) directly on
  # learndash_courses. They now live here so a price change can be scheduled ahead of
  # time: each CourseFeeHistory covers a date range (start_on..end_on), and the price
  # for a given date is read from whichever history covers it.
  #
  # There should always be exactly one open-ended (end_on: nil) history per course — the
  # currently active prices. Read them via LearndashCourse#prices.
  class CourseFeeHistory < ActiveRecord::Base
    belongs_to :learndash_course, class_name: 'Effective::LearndashCourse'

    log_changes(to: :learndash_course) if respond_to?(:log_changes)

    effective_resource do
      start_on      :date
      end_on        :date

      regular_fee   :integer      # Price to applicants or new users
      member_fee    :integer      # Price to existing members

      timestamps
    end

    scope :deep, -> { includes(:learndash_course) }
    scope :sorted, -> { order(start_on: :desc) }

    validates :start_on, presence: true
    validates :end_on, comparison: { greater_than: :start_on }, allow_nil: true

    # Price presence used to be validated on the course; it moved here with the prices.
    with_options(if: -> { learndash_course&.can_register? }) do
      validates :regular_fee, presence: true
      validates :member_fee, presence: true
    end

    def to_s
      "#{learndash_course} Fees #{start_on&.year}#{" - #{end_on.year}" if end_on.present?}"
    end

    # Schedule next year's prices: close the current (open-ended) prices at the end of this
    # year and open a copy for next year, ready to have its new prices set.
    def duplicate!
      transaction do
        copy = dup
        copy.assign_attributes(start_on: (Time.zone.now + 1.year).beginning_of_year, end_on: nil)
        copy.save!

        update!(end_on: Time.zone.now.end_of_year)
      end
    end
  end
end
