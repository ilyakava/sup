[![Build Status](https://travis-ci.org/ilyakava/sup.svg?branch=generalize)](https://travis-ci.org/ilyakava/sup)
[![Stories in Ready](https://badge.waffle.io/ilyakava/sup.png?label=ready&title=Ready)](https://waffle.io/ilyakava/sup)

## About

This is a web app for facilitating S'Ups (quick meetings) between the employees of a company.

A Standup is a regular meeting between the members of a specialized team to discuss their team's goals, and priorities for achieving those goals. A S'Up is instead an informal and interdisciplinary standup, where members discuss what's up with their own work, or just in general.

Like S'Up is short for standup. Hopefully, S'Up will help people form connections with their colleagues that they normally aren't nearby or working with, creating a lattice of connections throughout a whole un-fragmented company.

### Before S'Up

*Here is a graph of a sample company's employees connected together via their group co-memberships. The graph has clear hubs, and the number of bonds per employee (node) is unequal throughout.*

![sample image of a company graph](http://f.cl.ly/items/3e3B2f350a2b2s3O1z1T/sample_graph.png) [hi res here](http://f.cl.ly/items/0Z0g3K3l3t3h3Q1F1f1w/sample_graph.png)

### After S'Up

*Here is a graph of a sample company's employees connected together via their S'Up co-memberships. The graph is distributed and clustering is starting to disappear. You can see employees who signed up for S'Up later (bottom right corner) have yet to be completely subsumed by the plane of spaghetti.*

![sample image of a company after 6 weeks of S'Up](http://f.cl.ly/items/0u3e45142d0S3J0U143B/after.png) [hi res here](http://f.cl.ly/items/2t0F1U441j3B1v0J342M/after.png)

# Usage

## Deployment

This is a rails app that can easily be [deployed with heroku](https://devcenter.heroku.com/articles/getting-started-with-rails4). The only requirement is to set some environment variables for your own sup app.

### Environment variables

This app uses the [figaro](https://github.com/laserlemon/figaro) gem, so it is recommended that you place all your environment variables in a `application.yml` file in the root of the app. The **required** environment variables are:

```
COMPANY_NAME: "Initech"
COMPANY_NAME_POSSESSIVE: "Initech's"
PRODUCTION_DOMAIN: "guarded-stream-9823.herokuapp.com"
SMTP_USER_NAME: "ilyakava@initech.com"
SMTP_PASSWORD: "lumberghrulz"
SMTP_DOMAIN: "guarded-stream-9823.herokuapp.com
```

- `COMPANY_NAME` and `COMPANY_NAME_POSSESSIVE` are used in email copy and on the website to refer to your company.
- `PRODUCTION_DOMAIN` should be the web address (without `http` or `www`) for where you are hosting your app.
- `SMTP_USER_NAME` and `SMTP_PASSWORD` are your email address user name and password. These are used by the app to automatically send emails from the given address.
- `SMTP_DOMAIN` can be the same as `PRODUCTION_DOMAIN`

An optional but **recommended** environment variable is:

```
COMPANY_MEMBER_EMAIL_REGEXP: "@initech|@inite\\.ch"
```

- This is a [regular expression](http://rubular.com/) that will be used to accept or reject people signing up for your app based on their email address. This one will only allow members to join with email addresses like `milton@initech.com` and `peter@inite.ch`. Note how escaping the literal period `\\.` takes two backslashes if you are using figaro (because of yml file parsing). Not providing this environment variable will lead to all email addresses being valid.

## Contributing

* Click on the waffle badge to check what needs to be done!

## Testing

run `rake fspec` to exclude the slow specs that check the consistency of the pairing algorithm, and `rake` to run all tests (several minutes).

## License

MIT
