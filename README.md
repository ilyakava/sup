[![Build Status](https://travis-ci.org/ilyakava/sup.svg?branch=generalize)](https://travis-ci.org/ilyakava/sup)
[![Stories in Ready](https://badge.waffle.io/ilyakava/sup.png?label=ready&title=Ready)](https://waffle.io/ilyakava/sup)

## About

This is a web app for facilitating S'Ups (quick meetings) between the employees of a company.

A Standup is a regular meeting between the members of a specialized team to discuss their team's goals, and priorities for achieving those goals. A S'Up is instead an informal and interdisciplinary standup, where members discuss what's up with their own work, or just in general.

Like S'Up is short for standup. Hopefully, S'Up will help people form connections with their colleagues that they normally aren't nearby or working with, creating a lattice of connections throughout a whole un-fragmented company.

### Before S'Up

*Here is a graph of a sample company's employees connected together via their **work team co-memberships**. The graph has **clear hubs**, and the number of bonds per employee (node) is unequal throughout.*

![sample image of a company graph](http://f.cl.ly/items/3e3B2f350a2b2s3O1z1T/sample_graph.png) [hi res here](http://f.cl.ly/items/0Z0g3K3l3t3h3Q1F1f1w/sample_graph.png)

### After S'Up

*Here is a graph of a sample company's employees connected together via their **S'Up co-memberships** after 6 weeks. The graph is **distributed** and clustering is starting to disappear. You can see employees who signed up for S'Up later (bottom right corner) have yet to be completely subsumed by the plane of spaghetti.*

![sample image of a company after 6 weeks of S'Up](http://f.cl.ly/items/0u3e45142d0S3J0U143B/after.png) [hi res here](http://f.cl.ly/items/2t0F1U441j3B1v0J342M/after.png)

## App Experience Overview

S'up contains a homepage which new users can sign up, edit their name/email and group membership, and also disable themselves from being included in S'ups temporarily in the case of a busy week.

![Sup on the web gif](http://f.cl.ly/items/1f0e0K2y1W3X0f0o1q0l/sup_web2.gif)

S'up sends emails on Sunday mornings with information about scheduled S'ups:

![Sup sunday email pic](http://f.cl.ly/items/0C2q3A3J2s373f0n1A1e/2Screen%20Shot%202014-07-25%20at%202.48.51%20PM.png)

and then sends a followup email the Saturday after the work week to confirm that the members have met (which will prevent them from meeting again until they have met with everyone else in the company), and asks for feedback.

![Sup on email gif](http://f.cl.ly/items/3A2d0P1Y052e061O311m/sup_email3.gif)

### S'up member matching

S'ups follow a few rules:

- You will never be in a S'up with a member of one of your teams.
- You will not meet with someone in the same S'up until you have met with everyone else possible on your team.

# Usage

- Clone/Fork this repo
- Deploy with environment variables
- Add cron tasks
- Add teams
- Tell members of your organization to sign up
- Automatically receive emails upon signup, Sunday emails for S'ups in the coming week, Saturday emails for confirming meetings in past weeks

## Deployment

This is a rails app that can easily be [deployed with heroku](https://devcenter.heroku.com/articles/getting-started-with-rails4), so the [instructions there can be followed](https://devcenter.heroku.com/articles/getting-started-with-rails4). The only requirement before deploying is to set some environment variables for your own sup app.

### Environment variables

This app uses the [figaro](https://github.com/laserlemon/figaro) gem, so it is recommended that you place all your environment variables in a `application.yml` file in the root directory of the app. The **required** environment variables are:

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

### Adding cron tasks (Heroku)

Follow the instructions about [heroku scheduler](https://devcenter.heroku.com/articles/scheduler) only in the "Installing the add-on" and "Scheduling jobs" sections. Then, after selecting [your app in the heroku dashboard](https://dashboard.heroku.com/apps), and clicking on "Heroku Scheduler," and add the following three jobs:

| Task                          | Dyno Size | Frequency | Last Run | Next Run  |
|-------------------------------|-----------|-----------|----------|-----------|
| `rake schedule_meetings`      | 1X        | Daily     | never    | 14:30 UTC |
| `rake trigger_weekly_email`   | 1X        | Daily     | never    | 15:00 UTC |
| `rake trigger_followup_email` | 1X        | Daily     | never    | 15:00 UTC |

Although the least frequent running choice is "Daily" on heroku, these jobs will actually be run on Friday, Sunday, and Saturday respectively (for info on why: look in `./lib/tasks/scheduler.rake`).

With the configuration in the above table: S'ups are scheduled 12:30pm EST on Friday, email invitations to S'ups are sent 11am EST on Sundays, and S'up followups are sent 11am on Saturday. This app will work fine without followup emails scheduled, but by responding to followup emails accurately, the quality of S'ups will be greater.

### Adding teams (Heroku)

Following the commented example in the `seeds.rb` file in the root directory, enter in all the teams at your company. Then run `heroku run db:seed`.

## Contributing

* Click here on this: [![Stories in Ready](https://badge.waffle.io/ilyakava/sup.png?label=ready&title=Ready)](https://waffle.io/ilyakava/sup) badge to check what needs to be done!

## Testing

Run `rake fspec` to exclude the slow specs that check the consistency of the pairing algorithm, and `rake` to run all tests (several minutes).

## License

MIT
