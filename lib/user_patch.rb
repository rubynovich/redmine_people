module RedminePeoplePlugin
  module UserPatch

    def self.included(base)
      #base.extend(ClassMethods)

      #base.send(:include, InstanceMethods)

      base.class_eval do

        validator = User._validators[:mail].find{|v| v.class == ActiveModel::Validations::FormatValidator }
        validator.instance_eval{ @options = {} }

      end

    end

  end
end