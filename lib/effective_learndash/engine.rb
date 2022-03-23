module EffectiveLearndash
  class Engine < ::Rails::Engine
    engine_name 'effective_learndash'

    # Set up our default configuration options.
    initializer 'effective_learndash.defaults', before: :load_config_initializers do |app|
      eval File.read("#{config.root}/config/effective_learndash.rb")
    end

    initializer 'effective_learndash.assets' do |app|
      app.config.assets.precompile += ['effective_learndash_manifest.js', 'effective_learndash/*']
    end

    # Include acts_as_addressable concern and allow any ActiveRecord object to call it
    initializer 'effective_learndash.active_record' do |app|
      ActiveSupport.on_load :active_record do
        ActiveRecord::Base.extend(EffectiveLearndashOwner::Base)
      end
    end

  end
end
