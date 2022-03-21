# Effective Learndash

Create Wordpress users and read Learndash course progress. This is an unoffocial integration that is not supported or affiliated with WordPress or Learndash.

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

```
Add a link to the admin menu:

```haml
- if can? :admin, :effective_learndash
  = nav_link_to 'Learndash', effective_learndash.admin_learndash_path
```

and visit `/admin/learndash`.

## Authorization

All authorization checks are handled via the effective_resources gem found in the `config/initializers/effective_resources.rb` file.

## Permissions

The permissions you actually want to define are as follows (using CanCan):

```ruby
if user.admin?
  can :admin, :effective_learndash
end
```

## Configuring Learndash

Your Wordpress should be configured ahead of time with the Learndash plugin.

Please generate an application password via:

https://make.wordpress.org/core/2020/11/05/application-passwords-integration-guide/

and fill in the username/password details in config/initializers/effective_leardash.rb

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
