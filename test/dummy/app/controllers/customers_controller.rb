class CustomersController < ApplicationController
  def create
    cmd = Customer::Commands::Create.new(
      first_name: params[:first_name],
      last_name: params[:last_name],
      email: params[:email]
    )

    RailsSimpleEventSourcing.dispatch(cmd)
      .on_success { |data| render json: data }
      .on_failure { |errors| render json: { errors: }, status: :unprocessable_entity }
  end

  def update
    cmd = Customer::Commands::Update.new(
      aggregate_id: params[:id],
      first_name: params[:first_name],
      last_name: params[:last_name],
      email: params[:email]
    )

    RailsSimpleEventSourcing.dispatch(cmd)
      .on_success { |data| render json: data }
      .on_failure { |errors| render json: { errors: }, status: :unprocessable_entity }
  end

  def destroy
    cmd = Customer::Commands::Delete.new(aggregate_id: params[:id])

    RailsSimpleEventSourcing.dispatch(cmd)
      .on_success { head :no_content }
      .on_failure { |errors| render json: { errors: }, status: :unprocessable_entity }
  end
end
