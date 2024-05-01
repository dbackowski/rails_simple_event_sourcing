class CustomersController < ApplicationController
  def create
    cmd = Customer::Commands::Create.new(
      first_name: params[:first_name],
      last_name: params[:last_name]
    )
    handler = RailsSimpleEventSourcing::CommandHandler.new(cmd).call

    if handler.success?
      render json: handler.data
    else
      render json: handler.errors, status: :unprocessable_entity
    end
  end

  def update
    cmd = Customer::Commands::Update.new(
      aggregate_id: params[:id],
      first_name: params[:first_name],
      last_name: params[:last_name]
    )
    handler = RailsSimpleEventSourcing::CommandHandler.new(cmd).call

    if handler.success?
      render json: handler.data
    else
      render json: handler.errors, status: :unprocessable_entity
    end
  end

  def destroy
    cmd = Customer::Commands::Delete.new(aggregate_id: params[:id])
    handler = RailsSimpleEventSourcing::CommandHandler.new(cmd).call

    if handler.success?
      render json: handler.data
    else
      render json: handler.errors, status: :unprocessable_entity
    end
  end
end
