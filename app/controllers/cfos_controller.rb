# encoding: UTF-8
class CfosController < ApplicationController
  unloadable

  before_filter :check_admin_user
  before_filter :find_cfo, only: [:update, :destroy, :edit]

  # GET /cfos
  # GET /cfos.json
  def index
    @cfos = Cfo.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @cfos }
    end
  end

  # GET /cfos/new
  # GET /cfos/new.json
  def new
    @cfo = Cfo.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @cfo }
    end
  end

  # GET /cfos/1/edit
  def edit
  end

  # POST /cfos
  # POST /cfos.json
  def create
    @cfo = Cfo.new(params[:cfo])

    respond_to do |format|
      if @cfo.save
        format.html { redirect_to cfos_url, notice: 'ЦФО создан.' }
        format.json { render json: @cfo, status: :created, location: @cfo }
      else
        format.html { render action: "new" }
        format.json { render json: @cfo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /cfos/1
  # PUT /cfos/1.json
  def update

    respond_to do |format|
      if @cfo.update_attributes(params[:cfo])
        format.html { redirect_to cfos_url, notice: 'ЦФО обновлён.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @cfo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cfos/1
  # DELETE /cfos/1.json
  def destroy
    @cfo.destroy
    respond_to do |format|
      format.html { redirect_to cfos_url }
      format.json { head :no_content }
    end
  end

  private

  def find_cfo
    @cfo = Cfo.find(params[:id])
  end

  def check_admin_user
    unless User.current.admin?
      render_403
      return false
    end
  end


end
