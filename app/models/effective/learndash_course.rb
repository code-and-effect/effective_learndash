module Effective
  class LearndashCourse < ActiveRecord::Base
    has_many :learndash_enrollments
    has_many :learndash_users, through: :learndash_enrollments

    # Dated prices. The open-ended (end_on: nil) history holds the current prices. Read via #prices.
    has_many :course_fee_histories, -> { order(start_on: :desc) },
      class_name: 'Effective::CourseFeeHistory', dependent: :destroy

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
      can_register           :boolean

      # Pricing now lives on dated course_fee_histories, read via #prices / #regular_price /
      # #member_price. These columns still exist in the database (a later migration drops them).
      # regular_price       :integer
      # member_price        :integer

      qb_item_name          :string
      tax_exempt            :boolean

      # Access
      roles_mask             :integer
      authenticate_user      :boolean

      timestamps
    end

    scope :deep, -> { all }
    scope :sorted, -> { order(:title) }
    scope :registerable, -> { where(can_register: true) }
    scope :published, -> { all }

    scope :paginate, -> (page: nil, per_page: nil) {
      page = EffectiveResources.normalize_page(page)
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

      # TODO
      # unless unpublished
      #   scope = scope.published
      # end

      scope
    }

    validates :course_id, presence: true
    validates :status, presence: true
    validates :title, presence: true

    # Price presence now lives on CourseFeeHistory (validated when can_register?).

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

    # Todo
    def draft?
      false
    end

    # The CourseFeeHistory (price list) in effect on the given date — today by default.
    # Prices used to live in flat columns here; read them off this record now:
    #
    #   course.prices.regular_fee                 # price right now
    #   course.prices(date: date).member_fee      # price in effect on date
    #
    # Raises if no history covers the date so misconfiguration surfaces loudly.
    def prices(date: nil)
      date = (date || Time.zone.now).to_date

      # course_fee_histories is ordered start_on desc — pick the newest window covering the
      # date. end_on nil makes an endless range (start_on..), i.e. the current prices.
      course_fee_histories.find { |history| (history.start_on..history.end_on).cover?(date) } ||
        raise("No course_fee_history prices available for #{self} on #{date.strftime('%F')}, add a course fee history covering that date")
    end

    # Backwards-compatible readers so existing call sites keep working after prices moved to
    # dated histories. These override the retired flat columns.
    def regular_price(date: nil)
      prices(date: date).regular_fee
    end

    def member_price(date: nil)
      prices(date: date).member_fee
    end

    # Non-blocking warnings about the price timeline, shown on the admin edit screen. Prices
    # should form one continuous timeline with a single open-ended (current) history.
    def course_fee_histories_warnings
      histories = course_fee_histories.sort_by(&:start_on)
      return ['No prices have been set — add a course fee history.'] if histories.empty?

      warnings = []

      current = histories.select { |history| history.end_on.blank? }
      warnings << 'There are no current prices — the most recent history should have no end date.' if current.empty?
      warnings << 'There is more than one current history (more than one with no end date).' if current.size > 1

      # Each history should pick up the day after the previous one ends — no gaps, no overlaps.
      histories.each_cons(2) do |earlier, later|
        next if earlier.end_on.blank? # an open-ended history in the middle is flagged above

        if later.start_on > earlier.end_on + 1.day
          warnings << "Gap in prices between #{earlier.end_on} and #{later.start_on}."
        elsif later.start_on <= earlier.end_on
          warnings << "Overlapping prices around #{later.start_on}."
        end
      end

      warnings
    end

  end
end
