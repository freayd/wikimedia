require 'active_record'
require_relative 'load_wikivoyage'

task :default => :migrate
 
desc 'Migrate the database (options: VERSION=x)'
task :migrate => :environment do
    migrations_paths = 'db/migrate'
    version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil
    ActiveRecord::Migrator.migrate(migrations_paths, version)
end
 
task :environment do
    # TODO Change: the Rakefile is generic (supposed to work for all wikis) but this code is Wikivoyage only!
    open_wikivoyage
end
