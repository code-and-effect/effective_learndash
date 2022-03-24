# EffectiveLearndashOwner
#
# Mark your user model with effective_learndash_owner to get all the includes

module EffectiveLearndashOwner
  extend ActiveSupport::Concern

  module Base
    def effective_learndash_owner
      include ::EffectiveLearndashOwner
    end
  end

  module ClassMethods
    def effective_learndash_owner?; true; end
  end

  included do
    # Effective Scoped - this is a has_one in preactice
    has_many :learndash_users, class_name: 'Effective::LearndashUser', as: :owner, inverse_of: :owner, dependent: :delete_all
    accepts_nested_attributes_for :learndash_users, allow_destroy: true
  end

  def learndash_user
    learndash_users.first
  end

  def find_or_create_learndash_user
    learndash_user || create_learndash_user!
  end

  private

  def create_learndash_user!
    raise('must be persisted to create a learndash user') unless persisted?
    learndash_users.create!(owner: self)
  end

end
