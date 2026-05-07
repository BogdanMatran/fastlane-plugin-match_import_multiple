require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?(:UI)

  module Helper
    class MatchImportMultipleHelper
      # class methods that you define here become available in your action
      # as `Helper::MatchImportMultipleHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the match_import_multiple plugin helper!")
      end
    end
  end
end
