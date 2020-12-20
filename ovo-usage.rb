require 'sinatra'
require './lib/downloader'

set :public_folder, 'public'

get '/' do
  erb :index, layout: true
end

post '/request-download' do
  downloader = Downloader.new(params['ovo_id'], params['ovo_password'])
  redirect to('/?e=unauthenticated')  if downloader.authenticate == :unauthenticated

  download_id = downloader.download

  redirect to("/download/#{download_id}")
end

get '/download/:id' do |id|
  return erb :download_pending
  results = Downloader.cached(id)
  if results == 302
    # redirect request.url
    erb :download_pending
  elsif results == 404
    status 404
  else
    content_type 'application/csv'
    headers({
      'Content-Disposition' => 'attachment; filename=ovo-electricity-usage.csv'
    })
    results
  end
end
