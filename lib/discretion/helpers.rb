module Discretion
  class << self
    def in_console?
      defined?(Rails::Console)
    end

    def in_test?
      Rails.env.test?
    end

    def can_see_models?(viewer, *models)
      models.all? do |model|
        Discretion.can_see_model?(viewer, model)
      end
    end

    def can_write_models?(viewer, *models)
      models.all? do |model|
        Discretion.can_write_model?(viewer, model)
      end
    end
  end
end
