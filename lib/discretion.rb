require 'discretion/can'
require 'discretion/current_viewer'
require 'discretion/discreet_model'
require 'discretion/errors'
require 'discretion/helpers'
require 'discretion/meta'
require 'discretion/middleware'
require 'discretion/railtie' if defined?(Rails)
require 'discretion/version'

ActiveRecord::Base.send(:include, Discretion::Meta) if defined?(ActiveRecord)
