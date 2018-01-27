module Discretion
  class << self
    def in_console?
      defined?(Rails::Console).present?
    end

    def in_test?
      Rails.env.test?
    end

    def can_see_records?(viewer, *records)
      records.all? { |record| Discretion.can_see_record?(viewer, record) }
    end
  end
end
