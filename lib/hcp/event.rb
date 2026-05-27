module Hcp
  class Event
    # @see https://docs.housecallpro.com/docs/housecall-public-api/46e9e1be07621-webhooks
    SIGNATURE_HEADER = 'Api-Signature'

    # @see https://docs.housecallpro.com/docs/housecall-public-api/46e9e1be07621-webhooks
    TIMESTAMP_HEADER = 'Api-Timestamp'

    # @param params [Hash] the payload for an event webhook.
    def initialize(params = {})
      @params = params
    end

    # @return [Symbol] the type of event, e.g.: :lead_converted, :job_created, :invoice_sent.
    def type = @params[:event].gsub('.', '_').to_sym

    # @return [String] unique identifier of the lead in a :lead_converted event.
    def lead_id = @params.dig :lead, :id

    # @return [String] unique identifier of the customer in a :lead_converted or :job_created event.
    def customer_id = @params.dig resource_type, :customer, :id

    # @return [String] unique identifier of the job in a :job_created/scheduled/completed event.
    def job_id = @params.dig :job, :id

    # @return [String] unique identifier of the estimate in a :job_created event.
    def estimate_id = @params.dig :job, :original_estimate_id

    # @return [Symbol] the latest conversion type, can be :estimate or :job.
    def conversion_type = conversion['type'].downcase.to_sym

    # @return [String] the latest conversion ID, can be an estimate ID or a job ID.
    def conversion_id = conversion['id']

    # @return [Time] time when the job is scheduled a :job_scheduled event.
    def scheduled_at = Time.iso8601(@params.dig :job, :schedule, :scheduled_start)

    # @return [Time] time when the job was completed a :job_completed event.
    def completed_at = Time.iso8601(@params.dig :job, :work_timestamps, :completed_at)

    # @return [String] unique identifier of the invoice in an :invoice_sent event.
    def invoice_id = @params.dig :invoice, :id

    # @return [String] unique identifier of the job in an :invoice_sent event.
    def invoice_job_id = @params.dig :invoice, :job_id

    # @return [BigDecimal] dollar amount of the invoice in an :invoice_sent event.
    def invoice_amount = BigDecimal(@params.dig :invoice, :amount) / 100.0

  private

    # @return [Hash] the latest conversion, applies to 'lead.converted' events.
    def conversion = @params.dig(:lead, :conversions).last

    # @return [Symbol] the type of resource affected by the event, can be :lead or :job.
    def resource_type = @params[:event].split('.').first.to_sym
  end
end
