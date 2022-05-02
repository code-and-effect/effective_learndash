# frozen_stcourse_registrant_literal: true

# EffectiveLearndashCourseRegistration
#
# Mark your owner model with effective_learndash_course_registration to get all the includes

module EffectiveLearndashCourseRegistration
  extend ActiveSupport::Concern

  module Base
    def effective_learndash_course_registration
      include ::EffectiveLearndashCourseRegistration
    end
  end

  module ClassMethods
    def effective_learndash_course_registration?; true; end
  end

  included do
    acts_as_purchasable_parent
    acts_as_tokened

    acts_as_statused(
      :draft,      # Just Started
      :submitted   # All done
    )

    acts_as_wizard(
      start: 'Start',
      course: 'Course',
      summary: 'Review',
      billing: 'Billing Address',
      checkout: 'Checkout',
      submitted: 'Submitted'
    )

    acts_as_purchasable_wizard

    log_changes(except: :wizard_steps) if respond_to?(:log_changes)

    # Application Namespace
    belongs_to :owner, polymorphic: true
    accepts_nested_attributes_for :owner

    # Effective Namespace
    belongs_to :learndash_course, class_name: 'Effective::LearndashCourse'

    has_many :course_registrants, -> { order(:id) }, class_name: 'Effective::CourseRegistrant', inverse_of: :course_registration, dependent: :destroy
    accepts_nested_attributes_for :course_registrants, reject_if: :all_blank, allow_destroy: true

    has_many :orders, -> { order(:id) }, as: :parent, class_name: 'Effective::Order', dependent: :nullify
    accepts_nested_attributes_for :orders

    effective_resource do
      # Acts as Statused
      status                 :string, permitted: false
      status_steps           :text, permitted: false

      # Dates
      submitted_at           :datetime

      # Acts as Wizard
      wizard_steps           :text, permitted: false

      timestamps
    end

    scope :deep, -> { includes(:owner, :orders, :course_registrants) }
    scope :sorted, -> { order(:id) }

    scope :in_progress, -> { where.not(status: [:submitted]) }
    scope :done, -> { where(status: [:submitted]) }

    scope :for, -> (user) { where(owner: user) }

    # All Steps validations
    validates :owner, presence: true

    # Course Step
    validate(if: -> { current_step == :course }) do
      self.errors.add(:course_registrants, "can't be blank") unless present_course_registrants.present?
    end

    # All Fees and Orders
    def submit_fees
      course_registrants
    end

    # Enroll them in all courses.
    def after_submit_purchased!
      course_registrants.each { |registrant| registrant.owner.create_learndash_enrollment(course: registrant.learndash_course) }
    end

  end

  # Instance Methods
  def to_s
    persisted? ? "#{learndash_course} - #{owner}" : 'course registration'
  end

  def course
    learndash_course
  end

  def in_progress?
    draft?
  end

  def done?
    submitted?
  end

  def course_registrant
    course_registrants.first
  end

  def build_course_registrant
    course_registrants.build(owner: owner, learndash_course: learndash_course)
  end

  def learndash_owner
    (course_registrant&.owner || owner)
  end

  def member_pricing?
    learndash_owner.membership_present?
  end

  def registration_price
    raise('expected a learndash course') unless learndash_course.present?
    raise('expected a learndash owner') unless learndash_owner.present?

    member_pricing? ? learndash_course.member_price : learndash_course.regular_price
  end

  def assign_pricing
    course_registrant.assign_attributes(
      price: registration_price,
      qb_item_name: learndash_course.qb_item_name,
      tax_exempt: learndash_course.tax_exempt
    )
  end

  # After the course step.
  def course!
    raise('expected a learndash course') unless learndash_course.present?
    raise('expected a course_registrant to be present') unless course_registrant.present?
    raise('expected a course_registrant to have an owner') unless course_registrant.owner.present?
    raise('expected a learndash owner') unless learndash_owner.class.try(:effective_learndash_owner?)

    # Assign prices
    assign_pricing()
    raise('expected course_registrants to have a price') if course_registrants.any? { |registrant| registrant.price.blank? }

    # Save record
    save!

    # Create a learndash user now before payment to catch any errors in server stuff before payment.
    learndash_owner.create_learndash_user
    raise('expected a persisted learndash user') unless learndash_owner.learndash_user&.persisted?

    true
  end

  private

  def present_course_registrants
    course_registrants.reject(&:marked_for_destruction?)
  end

end
