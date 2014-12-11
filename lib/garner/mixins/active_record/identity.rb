module Garner
  module Mixins
    module ActiveRecord
      class Identity
        include Garner::Cache::Binding

        attr_accessor :klass, :handle, :proxy_binding, :conditions

        # Instantiate a new Mongoid::Identity.
        #
        # @param klass [Class] A
        # @param handle [Object] A String, Fixnum, BSON::ObjectId, etc.
        #   identifying the object.
        # @return [Garner::Mixins::Mongoid::Identity]
        def self.from_class_and_handle(klass, handle)
          validate_class!(klass)

          new.tap do |identity|
            identity.klass = klass
            identity.handle = handle
            identity.conditions = conditions_for(klass, handle)
          end
        end

        def initialize
          @conditions = {}
        end

        # Return an object that can act as a binding on this identity's behalf.
        #
        # @return [Mongoid::Document]
        def proxy_binding
          return nil unless handle
          @proxy_binding ||= klass.where(conditions).only(:_id, :_type, :updated_at).limit(1).entries.first
        end

        # Stringize this identity for purposes of marshaling.
        #
        # @return [String]
        def to_s
          "#{self.class.name}/klass=#{klass},handle=#{handle}"
        end

        def self.validate_class!(klass)
          if !klass.superclass.name.include?('ActiveRecord::Base')
            fail 'Must instantiate from a ActiveRecord class'
          end
        end

        def self.conditions_for(klass, handle)
          # Multiple-ID conditions
          arel_table = klass.arel_table
          conditions = Garner.config.active_record_identity_fields.map do |field|
            arel_table[field].eq(handle)
          end
          combined_conditions = conditions.inject { |query, condition| query.send(:or, condition) }
          combined_conditions
        end
      end
    end
  end
end
