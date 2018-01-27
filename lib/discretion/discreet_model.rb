require 'active_support/concern'

module Discretion
  module DiscreetModel
    extend ActiveSupport::Concern

    included do
      after_initialize do |record|
        raise Discretion::CannotSeeError unless Discretion.current_viewer_can_see_record?(record)
      end

      before_save do |record|
        raise Discretion::CannotWriteError unless Discretion.current_viewer_can_write_record?(record)
      end
    end
  end
end
