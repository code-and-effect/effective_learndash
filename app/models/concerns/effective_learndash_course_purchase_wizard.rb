# frozen_stcourse_purchase_literal: true

# EffectiveLearndashCoursePurchaseWizard
#
# Mark your owner model with effective_learndash_course_purchase_wizard to get all the includes

module EffectiveLearndashCoursePurchaseWizard
  extend ActiveSupport::Concern

  module Base
    def effective_learndash_course_purchase_wizard
      include ::EffectiveLearndashCoursePurchaseWizard
    end
  end

  module ClassMethods
    def effective_learndash_course_purchase_wizard?; true; end
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
      select: 'Select Course',
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
    has_many :course_purchases, -> { order(:id) }, class_name: 'Effective::CoursePurchase', inverse_of: :course_purchase_wizard, dependent: :destroy
    accepts_nested_attributes_for :course_purchases, reject_if: :all_blank, allow_destroy: true

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

    scope :deep, -> { includes(:owner, :orders, :course_purchases) }
    scope :sorted, -> { order(:id) }

    scope :in_progress, -> { where.not(status: [:submitted]) }
    scope :done, -> { where(status: [:submitted]) }

    scope :for, -> (user) { where(owner: user) }

    # All Steps validations
    validates :owner, presence: true

    # Course Step
    validate(if: -> { current_step == :course }) do
      self.errors.add(:course_purchases, "can't be blank") unless present_course_purchases.present?
    end

    # All Fees and Orders
    def submit_fees
      course_purchases
    end

    def after_submit_purchased!
      # Nothing to do yet
    end

  end

  # Instance Methods
  def to_s
    'course purchase payment'
  end

  def in_progress?
    draft?
  end

  def done?
    submitted?
  end

  def course_purchase
    course_purchases.first
  end

  def build_course_purchase
    course_purchase = course_purchases.build(owner: owner)

    if (address = owner.try(:shipping_address) || owner.try(:billing_address)).present?
      course_purchase.shipping_address = address
    end

    course_purchase
  end

  def assign_pricing
    raise('to be implemented by including class')

    # raise('expected a persisted course_purchase') unless course_purchase&.persisted?

    # price = case course_purchase.metal
    #   when '14k Yellow Gold' then 450_00
    #   when 'Sterling Silver' then 175_00
    #   when 'Titanium' then 50_00
    #   else
    #     raise "unexpected course_purchase metal: #{course_purchase.metal || 'none'}"
    #   end

    # qb_item_name = "Professional course_purchase"
    # tax_exempt = false

    # course_purchase.assign_attributes(price: price, qb_item_name: qb_item_name, tax_exempt: tax_exempt)
  end

  # After the configure selet step
  def select!
    assign_pricing() if course_purchase.present?
    raise('expected course_purchase to have a price') if course_purchase.price.blank?

    save!
  end

  private

  def present_course_purchases
    course_purchases.reject(&:marked_for_destruction?)
  end

end
