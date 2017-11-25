module Discretion
  module Meta
    extend ActiveSupport::Concern

    class_methods do
      def use_discretion
        include Discretion::DiscreetModel
      end
    end
  end
end
