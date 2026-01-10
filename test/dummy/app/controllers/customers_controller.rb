class CustomersController < ApplicationController
  def create
    cmd = Customer::Commands::Create.new(
      first_name: params[:first_name],
      last_name: params[:last_name],
      email: params[:email]
    )
    handler = RailsSimpleEventSourcing::CommandHandler.new(cmd).call

    if handler.success?
      render json: handler.data
    else
      render json: { errors: handler.errors }, status: :unprocessable_entity
    end
  end

  def update
    cmd = Customer::Commands::Update.new(
      aggregate_id: params[:id],
      first_name: params[:first_name],
      last_name: params[:last_name],
      email: params[:email]
    )
    handler = RailsSimpleEventSourcing::CommandHandler.new(cmd).call

    if handler.success?
      render json: handler.data
    else
      render json: { errors: handler.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    cmd = Customer::Commands::Delete.new(aggregate_id: params[:id])
    handler = RailsSimpleEventSourcing::CommandHandler.new(cmd).call

    if handler.success?
      head :no_content
    else
      render json: { errors: handler.errors }, status: :unprocessable_entity
    end
  end
end
