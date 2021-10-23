# frozen_string_literal: true

ActiveRecord::Base.configurations = { 'test' => { adapter: 'sqlite3', database: ':memory:' } }
ActiveRecord::Base.establish_connection :test
ActiveRecord::Migration.verbose = false

class MigrateSqlDatabase < ActiveRecord::Migration[6.1]
  def self.up
    create_table(:release_feature_items) do |t|
      t.string :name
      t.string :environment
      t.datetime :open_at
      t.datetime :close_at
    end
  end
end

MigrateSqlDatabase.up
