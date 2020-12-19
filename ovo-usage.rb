require 'sinatra'
require './lib/downloader'

get '/' do
  erb :index
end

post '/download' do
  downloader = Downloader.new(params['ovo_id'], params['ovo_password'])
  redirect to('/?e=unauthenticated')  if downloader.authenticate == :unauthenticated

  content_type 'application/csv'
  headers({
    'Content-Disposition' => 'attachment; filename=ovo-electricity-usage.csv'
  })

  stream do |out|
    downloader.download do |line|
      out << line
      out << "\0" 
    end
    out.close
  end
end
