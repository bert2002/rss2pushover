
RSS to pushover.net 
=============

Pushing RSS feeds to your Android/iOS using pushover.net

Features
-------

* parsing rss feed and push new article
* database for article managment

Usage
-------

$ rss2pushover-single.pl --url "http://www.exbir.de/index.php?format=feed&type=rss"

Database Schema (single)
-------

CREATE TABLE data (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, title TEXT, md5title TEXT, link TEXT, description TEXT);

Known Problems
-------

* no feed management and multipli device support


