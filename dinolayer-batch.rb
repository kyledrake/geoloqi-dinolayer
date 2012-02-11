## Geoloqi Dinolayer (BATCH EDITION)
#
# Detects when you have stumbled over where a dinosaur has been found, and tells you which Dinosaur!
# It also provides a link to the Dinosaurs' wikipedia page so you can read more about it.
#
# This is the batched version, which sends many requests at a time. It should be much faster than dinolayer.rb.
#
# Author: Kyle Drake
#
# License: Source code is BSD 2-clause.
#
# The dinosaurs.txt is not the same license: it comes from the PaleoDB, and I believe you are free to re-use it (but there are terms,
# see the site for more information).
#
# The database work comes from the following major contributors:
# Matt Carrano (84.7%)
# John Alroy (7.8%)
#
# Additional contributors include Kay Behrensmeyer, Roger Benson, Kevin Boyce, Richard Butler, Matthew Clapham,
# Will Clyde, Emmanuel Fara, Jason Head, John Hunter, Philip Mannion, Oliver Rauhut, Mark Uhen, Loic Villier,
# Xiaoming Wang, and Robin Whatley.


# The Geoloqi gem is required. You can install with "bundle install" or "gem install geoloqi".

require 'geoloqi'
require 'csv'


# Your access token. Retreive from https://developers.geoloqi.com
ACCESS_TOKEN = ARGV[0]

if ACCESS_TOKEN.nil?
  puts "You need to provide an access token. Retrieve from https://developers.geoloqi.com"
  puts "Usage: ruby ./dinolayer.rb YOUR_ACCESS_TOKEN"
  exit 1
end


# Approximate ground level line-of-sight, in meters
LINE_OF_SIGHT = (4.8*1000).freeze


# Initialize a Geoloqi Session object using the access token.

geoloqi = Geoloqi::Session.new access_token: ACCESS_TOKEN


# Create a special layer for the Dinosaurs to live in!
layer = geoloqi.post 'layer/create', name: 'Dinosaurs Two', key: 'dinosaurs_two'


# Iterate through the TSV (Tab Separated Variables) file.

place_create_requests = []
first_row = true
CSV.foreach("dinosaurs.tsv", col_sep: "\t", encoding: 'ISO-8859-1:UTF-8') do |dino_row|


  # The first row is the index, so we skip over it.
  if first_row
    dinosaur_index = dino_row
    first_row = false
    next
  end


  # Sort Dinosaur data into readable hash.

  dino = {
    id:        dino_row[0],
    name:      dino_row[2],
    latitude:  dino_row[9],
    longitude: dino_row[10]
  }


  # Queue the place information to represent the Dinosaur location.

  place_create_requests << {
    layer_id:  layer[:layer_id],
    key:       dino[:id],
    name:      dino[:name],
    latitude:  dino[:latitude],
    longitude: dino[:longitude],
    radius:    LINE_OF_SIGHT
  }

end


puts "Sending #{place_create_requests.length} dinosaur places to Geoloqi and adding Geotriggers. This will take a moment.."
puts "Watch and manage visually with the Layer Editor! It's located here: https://geoloqi.com/layers/#{layer[:layer_id]}/edit"


# Batch create Dinosaur places!

place_responses = geoloqi.batch do
  place_create_requests.each { |request| send :post, 'place/create', request }
end


# Create the a batch job to create Geotriggers, which will send messages to users subscribed to the layer when they enter a Dinosaur place.

geotrigger_responses = geoloqi.batch do

  place_responses.each do |place_response|

    place = place_response[:body]

    send :post, 'trigger/create', {
      place_id: place[:place_id],
      type:     'message',
      text:     "A#{'n' if %w{a e i o u}.include?(place[:name][0].downcase)} #{place[:name]} was found where you are right now",
      url:      "http://en.wikipedia.org/wiki/#{place[:name]}",
      key:      place[:key]
    }

  end

end

puts "DONE! Enjoy your Dinosaur Layer!"
