require File.expand_path('spec/spec_helper')
require "active_record"

Tempfile.open("yyy") do |f|
  database = "parallel_with_ar_test"

  ActiveRecord::Schema.verbose = false
  ActiveRecord::Base.establish_connection(
      :adapter => 'postgresql',
      :database => database,
      :pool => 5,
      :port => 5432,
      :reconnect => true
  )

  class User < ActiveRecord::Base
  end

  unless User.table_exists?
    ActiveRecord::Schema.define(:version => 1) do
      create_table :users do |t|
        t.string :name
      end
    end
  end



  User.delete_all

  User.create!(:name => "X")

  Parallel.each(1..8) do |i|
    @reconnected ||= User.connection.reconnect! || true
    puts "making user"
    User.create!(:name => i)
  end

  puts User.connection.reconnect!.inspect


  puts "User.count: #{User.count}"

  Parallel.map(1..8, :in_threads => 4) do |i|
    User.create!(:name => i)
  end

  User.create!(:name => "X")

  puts User.all.map(&:name).sort.join("-")
end
