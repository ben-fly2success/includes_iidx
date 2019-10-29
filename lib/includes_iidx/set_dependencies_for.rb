module IncludesIIDX
  module SetDependenciesFor
    def self.included(base)
      base.extend(ClassMethods)
      base.class_eval do
        scope :includes_iidx, lambda { |*attributes|
          to_include = iidx_to_include_for(*attributes).to_a
          to_include.any? ? includes(*to_include) : all
        }
      end
    end

    module ClassMethods
      def iidx_dependencies
        @iidx_dependencies ||= {}
      end

      def iidx_to_include_for(*attributes)
        IncludesIIDX::ResolveDependencies.perform_for(self, IncludesIIDX::DependenceSet.new(attributes))
      end

      def set_dependencies_for(name, deps)
        iidx_dependencies[name] = IncludesIIDX::DependenceSet.new(deps)
      end
    end
  end
end

ActiveRecord::Base.send :include, IncludesIIDX::SetDependenciesFor