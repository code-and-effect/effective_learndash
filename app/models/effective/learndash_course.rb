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

    acts_as_slugged
    log_changes if respond_to?(:log_changes)
    acts_as_role_restricted if respond_to?(:acts_as_role_restricted)

    effective_resource do
      # This user the wordpress credentials
      course_id             :integer
      title                 :string
      status                :string

      # Our attributes
      slug                   :string

      # For course purchases
      can_purchase          :boolean

      # Pricing
      regular_price         :integer
      member_price          :integer

      qb_item_name          :string
      tax_exempt            :boolean

      # Access
      roles_mask             :integer
      authenticate_user      :boolean

      timestamps
    end

    scope :deep, -> { all }
    scope :sorted, -> { order(:title) }
    scope :purchasable, -> { where(can_purchase: true) }

    scope :paginate, -> (page: nil, per_page: nil) {
      page = (page || 1).to_i
      offset = [(page - 1), 0].max * (per_page || EffectiveLearndash.per_page)

      limit(per_page).offset(offset)
    }

    scope :learndash_courses, -> (user: nil, unpublished: false) {
      scope = all.deep.sorted

      if defined?(EffectiveRoles) && EffectiveLearndash.use_effective_roles
        scope = scope.for_role(user&.roles)
      end

      if user.blank?
        scope = scope.where(authenticate_user: false)
      end

      # unless unpublished
      #   scope = scope.published
      # end

      scope
    }

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

    def body
      rich_text_body
    end

    def draft?
      false
    end

    def purchasable?
      return false if draft?
      can_purchase?
    end

  end
end
