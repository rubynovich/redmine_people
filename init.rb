require 'redmine_people'

Redmine::Plugin.register :redmine_people do
  name 'Redmine People plugin'
  author 'RedmineCRM'
  description 'This is a plugin for managing Redmine users'
  version '0.1.6'
  url 'http://redminecrm.com/projects/people'
  author_url 'mailto:support@redminecrm.com'

  requires_redmine :version_or_higher => '2.1.0'

  settings :default => {
    :users_acl => {},
    :visibility => ''
  }, :partial => 'people_settings/settings'


  Redmine::MenuManager.map :top_menu do |menu|


    parent = menu.exists?(:internal_intercourse) ? :internal_intercourse : :top_menu
    menu.push( :people, {:controller => 'people', :action => 'index', :project_id => nil, group_id: 455},
               { :parent => parent,
                 :caption => :label_people,
                 :if => Proc.new { User.current.allowed_people_to?(:view_people) }
               })

    menu.push( :departments, {:controller => 'departments', :action => 'index', :project_id => nil},
               { :parent => parent,
                 :caption => :label_company_structure,
                 :if => Proc.new { User.current.allowed_people_to?(:view_people) }
               })

  end

  menu :admin_menu, :people, {:controller => 'people_settings', :action => 'index'}, {:caption => :label_people}
  menu :admin_menu, :cfo, {:controller => 'cfos', :action => 'index'}, {:caption => :label_cfo}

  project_module :redmine_people do
    permission :edit_cfos, {:cfos => [:new, :create, :edit, :update, :destroy]}
    permission :view_cfos, {:cfos => [:index]}
  end

  require "user_patch"
  require_dependency 'user'
  require_dependency 'redmine/helpers/time_report.rb'
  require 'redmine_people/patches/time_report_helper_patch'

  require 'redmine_people/patches/time_entry_query_patch'
  require_dependency 'time_entry_query'

  require 'redmine_people/patches/timelog_helper_patch'
  require_dependency 'timelog_helper'



   [[TimelogHelper, RedminePeople::Patches::TimelogHelperPatch],[TimeEntryQuery, RedminePeople::Patches::TimeEntryQueryPatch],[User, RedminePeoplePlugin::UserPatch],[Redmine::Helpers::TimeReport, RedminePeople::Patches::TimeReportHelperPatch]].each do |cl, patch|
    cl.send(:include, patch) unless cl.included_modules.include? patch
   end



   #Redmine::Helpers::TimeReport.send(:include, )
end
