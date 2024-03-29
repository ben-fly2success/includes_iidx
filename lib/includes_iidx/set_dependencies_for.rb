module IncludesIIDX
  module SetDependenciesFor
    def self.included(base)
      base.extend(ClassMethods)
      base.class_eval do
        scope :includes_iidx, lambda { |*attributes|
          deps = iidx_deps_for(*attributes).to_a
          deps.any? ? includes(*deps) : all
        }
      end
    end

    module ClassMethods
      def iidx_dependencies
        @iidx_dependencies ||= {}
      end

      def iidx_deps_for(*attributes)
        IncludesIIDX::DependenceSet.new(attributes).resolve_for(self)
      end

      def set_dependencies_for(name, deps)
        iidx_dependencies[name] = IncludesIIDX::DependenceSet.new(deps)
      end
    end
  end
end

ActiveRecord::Base.send :include, IncludesIIDX::SetDependenciesFor