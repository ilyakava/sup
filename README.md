[![Stories in Ready](https://badge.waffle.io/ilyakava/xtal.png?label=ready&title=Ready)](https://waffle.io/ilyakava/xtal)
About
---

This is a web app for facilitating S'Ups between the employees of a company.

A Standup is a regular meeting between the members of a specialized team to discuss their team's goals, and priorities for achieving those goals. A S'Up is instead an informal and interdisciplinary standup, where members discuss what's up with their own work, or just in general.

Like S'Up is short for standup, [xtal](https://en.wikipedia.org/w/index.php?title=Xtal&redirect=no) is short for crystal. Hopefully, S'Up will help people form connections with their colleagues that they normally aren't nearby or working with, creating a lattice of connections throughout a whole un-fragmented company, like the atoms in a single crystal.

## Before S'Up

*Here is a graph of a sample company's employees connected together via their group co-memberships. The graph has clear hubs, and the number of bonds per employee (node) is unequal throughout.*

![sample image of a company graph](http://f.cl.ly/items/0Z0g3K3l3t3h3Q1F1f1w/sample_graph.png)

## After S'Up

*Here is a graph of a sample company's employees connected together via their S'Up co-memberships. The graph is distributed and clustering is starting to disappear. You can see employees who signed up for S'Up later (bottom right corner) have yet to be completely subsumed by the plane of spaghetti.*

![sample image of a company after 6 weeks of S'Up](http://f.cl.ly/items/2t0F1U441j3B1v0J342M/after.png)

---

Contributing
---

* Click on the waffle badge to check what needs to be done!

Testing
---

run `rspec . --tag ~speed:slow` to exclude the slow specs that check the consistency of the pairing algorithm
