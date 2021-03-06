module RedminePeoplePlugin
  module UserPatch
    extend ActiveSupport::Concern
    included do
      #self.inheritance_column = :_type_disabled
      validator = User._validators[:mail].find{|v| v.class == ActiveModel::Validations::FormatValidator }
      validator.instance_eval{ @options = {} }

      attr_accessor :_type_disabled
      #belongs_to :cfo
      #safe_attributes 'identity_url', 'cfo', 'cfo_id', 'person_cfo_id', 'person_cfo'
      #attr_accessible :login, :firstname, :lastname, :mail, :language, :admin, :auth_source_id, :password, :password_confirmation, :mail_notification, 'identity_url', 'cfo', 'cfo_id', 'person_cfo_id', 'person_cfo'
    end
  end
end