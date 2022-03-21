require 'effective_resources'
require 'effective_datatables'
require 'effective_learndash/engine'
require 'effective_learndash/version'

module EffectiveLearndash
  def self.config_keys
    [
      :learndash_url, :learndash_username, :learndash_password,
      :layout
    ]
  end

  include EffectiveGem

  def self.api
    Effective::LearndashApi.new
  end

end
