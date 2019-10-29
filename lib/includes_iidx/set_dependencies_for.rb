module IncludesIIDX
  module SetDependenciesFor
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def set_dependencies_for(name, deps)

      end
    end
  end
end

ActiveRecord::Base.send :include, IncludesIIDX::SetDependenciesFor