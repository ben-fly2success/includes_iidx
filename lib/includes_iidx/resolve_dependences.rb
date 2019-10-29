module IncludesIIDX
  class ResolveDependences
    def self.association_for(klass, name)
      klass.reflect_on_all_associations.each do |a|
        return a if a.name == name
      end
      nil
    end

    def self.associated_klass_for(klass, name)
      association_for(klass, name)&.klass
    end

    def self.class_deps(klass)
      if klass.respond_to?(:iidx_dependencies)
        klass.iidx_dependencies
      else
        {}
      end
    end

    def self.perform_for(klass, deps)
      res = IncludesIIDX::DependenceSet.empty

      deps.direct.each do |d|
        if (attr_deps = class_deps(klass)[d])
          res.merge!(perform_for(klass, attr_deps))
        else
          if d.in?(klass.translated_attribute_names)
            res.direct |= [:translations]
          elsif association_for(klass, d)
            res.direct |= [d]
          end
        end
      end
      deps.associated.each do |k, v|
        if (sub = associated_klass_for(klass, k))
          res.associated[k] = perform_for(sub, v)
        else
          res.associated[k] = v
        end
      end
      res
    end
  end
end
