namespace :effective_learndash do

  # bundle exec rake effective_learndash:seed
  task seed: :environment do
    load "#{__dir__}/../../db/seeds.rb"
  end

end
