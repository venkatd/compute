require 'compute'
require "active_record"
require 'with_model'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ":memory:")

RSpec.configure do |config|
  config.extend WithModel
end
