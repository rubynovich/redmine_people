class PeopleSettingsController < ApplicationController
  unloadable
  menu_item :people_settings

  layout 'admin'
  before_filter :require_admin
  before_filter :find_acl, :only => [:index]
  before_filter :find_skynet_observers, :only => [:index]

  helper :departments

  def index
    @departments = Department.all
  end

  def update
    settings = Setting.plugin_redmine_people
    settings = {} if !settings.is_a?(Hash)
    settings.merge!(params[:settings])
    Setting.plugin_redmine_people = settings
    flash[:notice] = l(:notice_successful_update)
    redirect_to :action => 'index', :tab => params[:tab]
  end

  def destroy
    PeopleAcl.delete(params[:id])
    find_acl
    respond_to do |format|
      format.html { redirect_to :controller => 'people_settings', :action => 'index'}
      format.js
    end    
  end

  def destroy_observer
    SkynetObserver.delete(params[:id])
    find_skynet_observers
    respond_to do |format|
      format.html { redirect_to :controller => 'people_settings', :action => 'index'}
      format.js
    end    
  end

  def autocomplete_for_user
    @principals = Principal.active.like(params[:q]).all(:limit => 100, :order => 'type, login, lastname ASC')
    render :layout => false
  end

  def skynet
    user_ids = params[:user_ids]
    user_ids.each do |user|
      SkynetObserver.create(user_id: user)
    end
    find_skynet_observers
    respond_to do |format|
      format.html { redirect_to :controller => 'people_settings', :action => 'index', :tab => 'skynet'}
      format.js 
    end 
  end

  def create
    user_ids = params[:user_ids]
    acls = params[:acls]
    user_ids.each do |user_id|
      PeopleAcl.create(user_id, acls)
    end
    find_acl
    respond_to do |format|
      format.html { redirect_to :controller => 'people_settings', :action => 'index', :tab => 'acl'}
      format.js 
    end 
  end

private

  def find_acl
    @users_acl = PeopleAcl.all
  end

  def find_skynet_observers
    @users_skynet = SkynetObserver.all
  end

end
