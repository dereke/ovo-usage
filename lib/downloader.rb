require 'csv'
require 'httpi'
require 'json'
require 'active_support/all'

class Downloader
  def initialize(ovo_id, ovo_password)
    @ovo_id = ovo_id
    @ovo_password = ovo_password
  end

  attr_accessor :ovo_id, :ovo_password

  def authenticate
    request = HTTPI::Request.new
    request.url = 'https://my.ovoenergy.com/api/v2/auth/login'
    request.body = { username: ovo_id, password: ovo_password, rememberMe: true }.to_json

    request.headers = { 'Content-Type' => 'application/json' }
    @auth_response = HTTPI.post(request)
    return :unauthenticated if @auth_response.code != 200

    @account_id = fetch_account_id
    :authenticated
  end

  def download
    day_request = HTTPI::Request.new
    day_request.set_cookies @auth_response.cookies

    yield(%w[start end consumption].to_csv)

    datetime_sequence(1.year.ago, DateTime.now, 1.day).each do |date|
      day_request.url = day_request_url(date)
      puts day_request.url
      day_response = HTTPI::get(day_request)
      day_json = JSON.parse(day_response.body)

      day_json['electricity']['data'].each do |entry|
        yield(entry_csv(entry))
      end if day_json['electricity']
    end
  end

  private

  def entry_csv(entry)
    [
      DateTime.parse(entry['interval']['start']).strftime('%Y-%m-%dT%H:%M'),
      DateTime.parse(entry['interval']['end']).strftime('%Y-%m-%dT%H:%M'),
      entry['consumption']
    ].to_csv
  end

  def datetime_sequence(start, stop, step)
    dates = [start]
    dates << (dates.last + step) while dates.last < (stop - step)
    dates
  end

  def day_request_url(date)
    "https://smartpaym.ovoenergy.com/api/energy-usage/half-hourly/#{@account_id}?date=#{date.strftime('%Y-%m-%d')}"
  end

  def fetch_account_id
    account_request = HTTPI::Request.new
    account_request.url = 'https://smartpaym.ovoenergy.com/api/customer-and-account-ids'
    account_request.set_cookies @auth_response.cookies

    account_response = HTTPI.get(account_request)
    account_json = JSON.parse(account_response.body)

    @account_id = account_json['accountIds'].first
  end
end
