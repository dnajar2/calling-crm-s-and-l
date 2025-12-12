module Ai
  module Tools
    class BaseTool
      def initialize(user)
        @user = user
      end

      def execute(input)
        raise NotImplementedError, "Subclasses must implement execute"
      end

      def self.schema
        raise NotImplementedError, "Subclasses must implement schema"
      end
    end
  end
end
