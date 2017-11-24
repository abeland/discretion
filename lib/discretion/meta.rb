module Discretion
  module Meta
    extend ActiveSupport::Concern

    class_methods do
      def be_discreet
        include Discretion::DiscreetModel
      end

      def use_discretion
        be_discreet
      end
    end
  end
end
