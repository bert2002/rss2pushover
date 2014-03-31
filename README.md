
RSS to pushover.net 
=============

Pushing RSS feeds to your Android/iOS using pushover.net

Features
-------

* parsing rss feed and push new article
* database for article and channel managment

Usage Example
-------

$ rss2pushover-single.pl --url "http://www.exbir.de/index.php?format=feed&type=rss"

$ rss2pushover.pl

Database Schema (single)
-------

CREATE TABLE data (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, title TEXT, md5title TEXT, link TEXT, description TEXT);


Database Schema (multi)
-------

CREATE TABLE channel (id INTEGER PRIMARY KEY AUTOINCREMENT, status INT, url TEXT, token TEXT, user TEXT);

CREATE TABLE data (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, title TEXT, md5title TEXT, link TEXT, description TEXT, channel INT);

Walkthrough
-------

To use the more advanced version with channel managment you need to create the multi database or just use rss2pushover.db.
Adding a new channel is done by manipulating the databse. There is no interface available yet.

sqlite> INSERT INTO channel (status, url, token, user) VALUES (1,$FEED_URL,$PUSH_TOKEN,$PUSH_USER);

* status -> enabled (1) or disabled (0)
* url -> url to the rss feed
* token -> token from pushover.net application
* user -> your pushover.net user key

After adding a channel the script can run:

$ perl rss2pushover.pl

Please dont forget to set the correct path and log directory in the script.

Known Problems
-------

* unknown


