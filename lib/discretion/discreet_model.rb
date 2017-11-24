module Discretion
  module DiscreetModel
    extend ActiveSupport::Concern

    included do
      after_initialize do |record|
        raise Discretion::CannotSeeError unless Discretion.current_viewer_can_see_record?(record)
      end

      before_save :assert_viewer_can_write

      private

      def assert_viewer_can_write
        raise Discretion::CannotSeeError unless Discretion.current_viewer_can_write_record?(record)
      end
    end
  end
end
