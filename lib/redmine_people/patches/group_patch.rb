require_dependency 'project'
require_dependency 'principal'
require_dependency 'user'

module RedminePeople
  module Patches
    module GroupPatch
      unloadable
      extend ActiveSupport::Concern
      included do
        has_and_belongs_to_many :people,
                                :after_add => :user_added,
                                :after_remove => :user_removed,
                                :class_name => 'Person',
                                :join_table => 'groups_users',
                                :association_foreign_key => 'user_id'
      end
    end
  end
end

unless Group.included_modules.include?(RedminePeople::Patches::GroupPatch)
  Group.send(:include, RedminePeople::Patches::GroupPatch)
end


