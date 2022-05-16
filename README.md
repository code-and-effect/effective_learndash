# Effective LearnDash

Create Wordpress users and read LearnDash course progress. This is an unofficial integration that is not supported or affiliated with WordPress or LearnDash.

## Getting Started

This requires Rails 6+ and Twitter Bootstrap 4 and just works with Devise.

Please first install the [effective_datatables](https://github.com/code-and-effect/effective_datatables) gem.

Please download and install the [Twitter Bootstrap4](http://getbootstrap.com)

Add to your Gemfile:

```ruby
gem 'haml-rails' # or try using gem 'hamlit-rails'
gem 'effective_learndash'
```

Run the bundle command to install it:

```console
bundle install
```

Then run the generator:

```ruby
rails generate effective_learndash:install
```

The generator will install an initializer which describes all configuration options and creates a database migration.

If you want to tweak the table names, manually adjust both the configuration file and the migration now.

Then migrate the database:

```ruby
rake db:migrate
```

Add to your user class:

```
class User < ApplicationRecord
  effective_learndash_owner
end
```

Add a link to the admin menu:

```haml
- if can? :admin, :effective_learndash
  = nav_dropdown 'Learndash' do
    - if can? :index, Effective::LearndashUser
      = nav_link_to 'Learndash Users', effective_learndash.admin_learndash_users_path

    - if can? :index, Effective::LearndashCourse
      = nav_link_to 'Learndash Courses', effective_learndash.admin_learndash_courses_path

    - if can? :index, Effective::LearndashEnrollment
      = nav_link_to 'Learndash Enrollments', effective_learndash.admin_learndash_enrollments_path
```

## Authorization

All authorization checks are handled via the effective_resources gem found in the `config/initializers/effective_resources.rb` file.

## Permissions

The permissions you actually want to define are as follows (using CanCan):

```ruby
can(:show, Effective::LearndashUser) { |lduser| lduser.owner_id == user.id }
can(:index, Effective::LearndashEnrollment)

can([:index, :show], Effective::LearndashCourse) { |course| !course.draft? }
can([:show, :index], Effective::CourseRegistrant) { |registrant| registrant.owner == user || registrant.owner.blank? }
can([:new, :create], EffectiveLearndash.CourseRegistration)
can([:show, :index], EffectiveLearndash.CourseRegistration) { |registration| registration.owner == user }
can([:update, :destroy], EffectiveLearndash.CourseRegistration) { |registration| registration.owner == user && !registration.was_submitted? }

if user.admin?
  can :admin, :effective_learndash

  can(crud + [:refresh], Effective::LearndashUser)
  can(crud + [:refresh], Effective::LearndashCourse)

  can(crud, Effective::LearndashEnrollment)
  can(:refresh, Effective::LearndashEnrollment) { |enrollment| !enrollment.completed? }
end
```

## Configuring LearnDash

Your WordPress should be configured ahead of time with the LearnDash plugin.

Please generate an application password via:

https://make.wordpress.org/core/2020/11/05/application-passwords-integration-guide/

and fill in the username/password details in config/initializers/effective_learndash.rb

## Working with LearnDash

Visit `/admin/learndash_courses` and Refresh the list of Courses.

Create a New LearnDash User will create a new WordPress/LearnDash account with a username/password according to the settings in the config file.

When you create a user, you only get access to the password once. So any existing users will have an unknown password.

Create a new LearnDash Enrollment to enroll a LearnDash user into a course. This will begin tracking their progress.

There are no webhooks or callbacks from LearnDash, everything is a GET request that updates the local database.

You can refresh an entire LearnDash user in one operation and it will sync the entire user at once, `user.learndash_user.refresh!`

## Delete User

If you need to delete a user, from wordpress:

1. Top Left Corner -> My Sites -> Network Admin -> Users

## License

MIT License. Copyright [Code and Effect Inc.](http://www.codeandeffect.com/)

## Testing

```ruby
rails test
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Bonus points for test coverage
6. Create new Pull Request
