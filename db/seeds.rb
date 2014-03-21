# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

teams = %w{Design Genome Institutions Gallery Editorial Communications Operations Legal Executive}
  .concat([
    'Product Operations & Analytics',
    'Core Engineering',
    'Mobile Engineering',
    'Partner Engineering',
    'Web Engineering',
    'Art Fair Partnerships',
    'Subscription Sales',
    'Artwork Sales'
  ])
teams.each { |name| Group.create(name: name)}
