module OnForm
  module Types
    class Type
      attr_reader :default

      def initialize(type, default)
        @type = type
        @default = default
      end
    end

    if ActiveRecord::Type.methods.include?(:lookup)
      def self.lookup(type, options)
        default = options.delete(:default)
        Type.new(ActiveRecord::Type.lookup(type, **options), default)
      end

      class Type
        def cast(arg)
          @type.cast(arg)
        end
      end
    else
      # for rails 4.2 and below, the type map lives on individual database adapters, but we may
      # not have any models, so here we fall back to the map defined by the abstract adapter class.
      def self.lookup(type, options)
        default = options.delete(:default)
        if precision = options.delete(:precision)
          if scale = options.delete(:scale)
            type = "#{type}(#{precision},#{scale})"
          else
            type = "#{type}(#{precision})"
          end
        elsif options[:scale]
          raise ArgumentError, "Can't apply scale without precision on Rails 4.2.  The precision is used when converting Float values."
        end
        raise ArgumentError, "Unknown type option: #{options}" unless options.empty?
        Type.new(_adapter.type_map.lookup(type), default)
      end

      def self._adapter
        @_adapter ||= ActiveRecord::ConnectionAdapters::AbstractAdapter.new(nil)
      end

      class Type
        def cast(arg)
          @type.type_cast_from_user(arg)
        end
      end
    end
  end
end
