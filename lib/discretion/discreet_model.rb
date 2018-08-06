require 'active_support/concern'

module Discretion
  module DiscreetModel
    extend ActiveSupport::Concern

    included do
      after_initialize do |record|
        raise Discretion::CannotSeeError unless Discretion.current_viewer_can_see_record?(record)
      end

      before_save do |record|
        unless Discretion.current_viewer_can_write_record?(record, changes, new_record?)
          raise Discretion::CannotWriteError
        end
      end

      before_destroy ->(record) {
        unless Discretion.current_viewer_can_destroy_record?(record)
          raise Discretion::CannotDestroyError
        end
      }, prepend: true
    end

    class_methods do
      def discreetly_read(attribute)
        attribute = attribute.to_sym

        define_method(attribute) {
          can_read_attr = if Discretion.currently_acting_as?(Discretion::OMNISCIENT_VIEWER) ||
                             Discretion.currently_acting_as?(Discretion::OMNIPOTENT_VIEWER)
                            true
                          else
                            yield(Discretion.current_viewer, self)
                          end

          raise Discretion::CannotSeeError unless can_read_attr

          read_attribute(attribute)
        }
      end
    end
  end
end
