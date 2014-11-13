class DinnersController < ApplicationController
  before_action :set_dinner, only: [:show, :edit, :update, :destroy, :join, :leave]
  before_action :authenticate_user!, only: [:create, :edit, :new, :update, :join, :leave]

  # GET /dinners
  # GET /dinners.json

  def index
    @dinners = Dinner.order('date').page(params[:page]).per(25) # (:order => 'dinner.date DESC')
  end

  # GET /dinners/1
  # GET /dinners/1.json
  def show
  end

  # GET /dinners/new
  def new
    @dinner = Dinner.new
  end

  # GET /dinners/1/edit
  def edit
  end

  # POST /dinners
  # POST /dinners.json
  def create
    @dinner = Dinner.new(dinner_params)
    @dinner.seats_available = @dinner.seats
    @dinner.host = current_user

    respond_to do |format|
      if @dinner.save
        format.html { redirect_to @dinner, notice: 'Supper successfully created.' }
        format.json { render :show, status: :created, location: @dinner }
      else
        format.html { render :new }
        format.json { render json: @dinner.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dinners/1
  # PATCH/PUT /dinners/1.json
  def update
    success = false
    if @dinner.host == current_user
      success = true
    end
    respond_to do |format|
      # FIXME: check seats and seats_available      
      if success and @dinner.update(dinner_params)
        format.html { redirect_to @dinner, notice: 'Suppr has been successfully updated.' }
        format.json { render :show, status: :ok, location: @dinner }
      else
        format.html { redirect_to @dinner, notice: 'You can not modify this Suppr.' }
        format.json { render json: @dinner.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dinners/1
  # DELETE /dinners/1.json
  def destroy
    success = false
    if @dinner.host == current_user
      @dinner.destroy
      success = true
    end
    respond_to do |format|
      format.html { redirect_to dinners_url, notice: success ? 'Suppr has been successfully destroyed.' : 'You can not delete this Suppr' }
      format.json { head :no_content }
    end
  end

  def leave
    success = false
    rsvp = @dinner.reservations.find_by(user_id: current_user.id, dinner: @dinner)
    if rsvp and @dinner.seats_available < @dinner.seats
      @dinner.seats_available += 1
      rsvp.destroy
      success = true
    end

    respond_to do |format|
      if success
        if @dinner.save
          format.js
          format.html { redirect_to dinners_url, notice: 'Successfully left a Suppr.' }
          format.json { render :show, status: :ok, location: dinners_url }
        else
          @dinner.errors.add(:leave, "We cannot complete your request.")
          format.js
          format.html { redirect_to dinners_url }
          format.json { render json: @dinner.errors, status: :unprocessable_entity }
        end
      else
        @dinner.errors.add(:leave, "We cannot complete your request.")
        format.js
        format.html { redirect_to dinners_url, notice: "We cannot complete your request."}
        format.json { render json: @dinner.errors, status: :unprocessable_entity }
      end
    end

    if @dinner.errors.has_key?(:leave)
      @dinner.errors.delete(:leave)
    end
  end

  def join
    success = true

    if @dinner.seats_available <= 0
      success = false
      error_msg = "no seats available."
    else
      @dinner.seats_available -= 1
      begin
        @dinner.reservations.create!({:dinner_id => @dinner.id, :user_id => current_user.id, :date => @dinner.date, :yday => @dinner.date.yday})
      rescue
        success = false
        error_msg = "you already has scheduled a Suppr in the same day."
      end
    end

    respond_to do |format|
      if success
        if @dinner.save
          format.js
          format.html { redirect_to @dinner, notice: 'Successfully joined to a Suppr.' }
          format.json { render :show, status: :ok, location: dinners_url }
        else
          @dinner.errors.add(:join, "Error, in elaborating your request")
          format.js
          format.html { redirect_to dinners_url }
          format.json { render json: @dinner.errors, status: :unprocessable_entity }
        end
      else
        @dinner.errors.add(:join, "Cannot join this Suppr: " + error_msg)
        format.js
        format.html { redirect_to dinners_url, notice: "Cannot join this Suppr"}
        format.json { render json: @dinner.errors, status: :unprocessable_entity }
      end
    end

    if @dinner.errors.has_key?(:join)
      @dinner.errors.delete(:join)
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dinner
      @dinner = Dinner.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def dinner_params
      params.require(:dinner).permit(:image, :date, :location, :title, :description, :category, :price, :seats, :stamp)
    end
end
