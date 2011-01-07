class EventsController < ApplicationController
  before_filter :authorize_act, :except => [:index, :calendar, :show]
  # GET /events
  # GET /events.xml
  def index
    category = params[:category] || 'all'
    # We should paginate this
    if category == 'past'
      @events = Event.past
      @heading = "Past Events"
    elsif category == 'future'
      @events = Event.upcoming
      @heading = "Upcoming Events"
    else
      #@events = Event.includes(:event_type).order(:start_time)
      @events = Event.all
      @heading = "All Events"
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @events }
    end
  end

  def calendar
    month = (params[:month] || Time.now.month).to_i
    year = (params[:year] || Time.now.year).to_i
    @start_date = Date.civil(year, month).beginning_of_month
    @end_date = Date.civil(year, month).end_of_month
    @events = Event.find(:all, :conditions => { :start_time => @start_date..@end_date }, :order => :start_time)
    # Really convoluted way of getting the first Sunday of the calendar, 
    # which usually lies in the previous month
    @calendar_start_date = (@start_date.wday == 0) ? @start_date : @start_date.next_week.ago(8.days)
    # Ditto for last Saturday
    @calendar_end_date = (@end_date == 0) ? @end_date.since(6.days) : @end_date.next_week.ago(2.days)

    respond_to do |format|
      format.html
      format.js {
        render :update do |page|
          page.replace 'calendar-wrapper', :partial => 'calendar'
        end
      }
    end
  end

  # GET /events/1
  # GET /events/1.xml
  def show
    @event = Event.find(params[:id])
    @blocks = @event.blocks
    @current_user_rsvp = @event.rsvps.find_by_person_id(@current_user.id) if @current_user
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @event }
    end
  end

  # GET /events/new
  # GET /events/new.xml
  def new
    @event = Event.new
    @blocks = @event.blocks

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @event }
    end
  end

  # GET /events/1/edit
  def edit
    @event = Event.find(params[:id])
    @blocks = @event.blocks
  end

  # POST /events
  # POST /events.xml
  def create
    @event = Event.new(params[:event])
    duration = @event.end_time - @event.start_time
    @blocks = []

    invalid = false
    case params[:rsvp_type]
    when 'No RSVPs'
    when 'Whole Event RSVPs'
      # Implies one block with the same start and end time as the event
      block = Block.new
      block.event = @event
      block.start_time = @event.start_time
      block.end_time = @event.end_time
      block.rsvp_cap = params[:rsvp_cap]
      @blocks << block
    when 'Block RSVPs'
      num_blocks = params[:num_blocks].to_i # Invalid strings are mapped to 0
      if params[:uniform_blocks]
        block_length = duration/num_blocks
        num_blocks.times do |i|
          block = Block.new
          block.event = @event
          start_time = @event.start_time + (block_length * i)
          block.start_time = start_time 
          block.end_time = start_time + block_length
          block.rsvp_cap = params[:rsvp_cap]
          @blocks << block
        end
      else
        # We assume that if block times are manually set, then they will appear
        # in params hashed as block0, block1, etc...
        num_blocks.times do |i|
          block = Block.new(params["block#{i}"])
          block.event = @event
          @blocks << block
        end
      end
    else
      invalid = true
    end
    @event.blocks = @blocks

    respond_to do |format|
      # Don't save event if any block is invalid
      ActiveRecord::Base.transaction do
        begin
          raise if invalid
          @event.save!
          @blocks.each do |block| 
            block.save!
          end

          format.html { redirect_to(@event, :notice => 'Event was successfully created.') }
          format.xml  { render :xml => @event, :status => :created, :location => @event }
        rescue
          format.html { render :action => "new" }
          format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # PUT /events/1
  # PUT /events/1.xml
  def update
    @event = Event.find(params[:id])
    @blocks = @event.blocks
    original_start = @event.start_time
    original_end = @event.end_time

    respond_to do |format|
      if @event.update_attributes(params[:event])
        num_blocks = Integer(params[:num_blocks]) 
        if num_blocks != @blocks.length || original_start != @event.start_time || original_end != @event.end_time
          @blocks.clear
          duration = @event.end_time - @event.start_time
          block_length = duration/num_blocks
          0.upto(num_blocks - 1) do |i|
            @blocks[i] = Block.new
            @blocks[i].event = @event
            @blocks[i].start_time = @event.start_time + (block_length * i)
            @blocks[i].end_time = @blocks[i].start_time + block_length
            @blocks[i].save
          end
        end
        format.html { redirect_to(@event, :notice => 'Event was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1
  # DELETE /events/1.xml
  def destroy
    @event = Event.find(params[:id])
    @event.destroy

    respond_to do |format|
      format.html { redirect_to(events_url) }
      format.xml  { head :ok }
    end
  end
end
