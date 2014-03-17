# encoding: UTF-8
class CfosController < ApplicationController
  unloadable

  # GET /cfos
  # GET /cfos.json
  def index
    if User.current.allowed_to?(:view_cfos, nil, {:global => true})
      @cfos = Cfo.all

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @cfos }
      end 
    else
      render_403
    end
  end

  # GET /cfos/new
  # GET /cfos/new.json
  def new
    if User.current.allowed_to?(:edit_cfos,  nil, {:global => true})
      @cfo = Cfo.new

      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @cfo }
      end
    else
      render_403
    end
  end

  # GET /cfos/1/edit
  def edit
    if User.current.allowed_to?(:edit_cfos,  nil, {:global => true})
      @cfo = Cfo.find(params[:id])
    else
      render_403
    end
  end

  # POST /cfos
  # POST /cfos.json
  def create
    if User.current.allowed_to?(:edit_cfos,  nil, {:global => true})
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
    else
      render_403
    end
  end

  # PUT /cfos/1
  # PUT /cfos/1.json
  def update
    if User.current.allowed_to?(:edit_cfos,  nil, {:global => true})
      @cfo = Cfo.find(params[:id])

      respond_to do |format|
        if @cfo.update_attributes(params[:cfo])
          format.html { redirect_to cfos_url, notice: 'ЦФО обновлён.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @cfo.errors, status: :unprocessable_entity }
        end
      end
    else
      render_403
    end
  end

  # DELETE /cfos/1
  # DELETE /cfos/1.json
  def destroy
    if User.current.allowed_to?(:edit_cfos,  nil, {:global => true})
      @cfo = Cfo.find(params[:id])
      @cfo.destroy

      respond_to do |format|
        format.html { redirect_to cfos_url }
        format.json { head :no_content }
      end
    else
      render_403
    end
  end
end
