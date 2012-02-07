## Geoloqi Dinolayer
#
# Detects when you have stumbled over where a dinosaur has been found, and tells you which Dinosaur!
# It also provides a link to the Dinosaurs' wikipedia page so you can read more about it.
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

require 'geoloqi'
require 'csv'

# Your access token. Retreive from https://developers.geoloqi.com
ACCESS_TOKEN = 'YOUR ACCESS TOKEN GOES HERE'

# Approximate ground level line-of-sight, in meters
LINE_OF_SIGHT = (4.8*1000).freeze

geoloqi = Geoloqi::Session.new access_token: ACCESS_TOKEN

# Create a layer for the Dinosaurs
layer = geoloqi.post 'layer/create', name: 'Dinosaurs', key: 'dinosaurs'

# Used to do batch updates, 50 at a time
batch_count = 0

first_row = true
CSV.foreach("dinosaurs.tsv", col_sep: "\t", encoding: 'ISO-8859-1:UTF-8') do |dino_row|
  if first_row
    dinosaur_index = dino_row
    first_row = false
    next
  end

  dino = {
    id:        dino_row[0],
    name:      dino_row[2],
    latitude:  dino_row[9],
    longitude: dino_row[10]
  }

  # Create a place to represent the Dinosaur location.
  dino_place = geoloqi.post 'place/create', {
    layer_id:  layer[:layer_id],
    key:       dino[:id],
    name:      dino[:name],
    latitude:  dino[:latitude],
    longitude: dino[:longitude],
    radius:    LINE_OF_SIGHT
  }

  # Create a Geotrigger to send a message to users subscribed to the layer when they enter the dino_place
  geotrigger = geoloqi.post 'trigger/create', {
    place_id: dino_place[:place_id],
    type:     'message',
    text:     "A#{'n' if %w{a e i o u}.include?(dino[:name][0].downcase)} #{dino[:name]} was found where you are right now",
    url:      "http://en.wikipedia.org/wiki/#{dino[:name]}",
    key:      dino[:id]
  }

  puts "Created place and geotrigger for #{dino[:name]} at #{dino[:latitude]}, #{dino[:longitude]}!"
  puts "Look at and manage visually at: https://geoloqi.com/layers/#{layer[:layer_id]}/edit"
end
