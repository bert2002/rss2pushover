#!/usr/bin/perl
# script: rss reader to pushover.net
# author: Steffen Wirth <s.wirth@itbert.de>

use strict;
use warnings;
no warnings 'utf8';
 
use LWP::UserAgent;
use Data::Dumper;
use DateTime;
use Getopt::Long;
use XML::Simple;
use Digest::MD5 qw(md5_hex);
use Encode qw(encode_utf8);
use DBI;

my $url;
my $help;

#
# Config
#

GetOptions (
	'u|url=s' => \$url,
	'h|help' => \$help
) or exit 1;

if ( ($help) || (!$url) ){
	print "Usage: $0\n";
  print " --url <url>\n";
  exit 0
}

# user configuration
my $DEBUG = "0"; # enable for stdout logging
my $LOGPATH = "/home/steffen/rss2pushover/log"; # path to log directory
my $SQLPATH = "/home/steffen/rss2pushover/rss2pushover.db"; # Path to sqlite3 database

# pushover.net configuration
my $PUSH_TOKEN = ""; # secret api token
my $PUSH_USER = ""; # user key

#
# Helper
#

# logging
mkdir "$LOGPATH/", 0777 unless -d "$LOGPATH";
open (LOGPATH, ">>$LOGPATH/rss2pushover.log") or die "can not open logfile $LOGPATH/mtgoxtrader.log";
sub mylog {
  my ($message) = @_;
  my $date = localtime;
  if ($DEBUG) {
   print         "$date  [$$] $message\n";
  } else {
   print LOGPATH "$date  [$$] $message\n";
  }
}

# sqlite
my $dbargs = {AutoCommit => 1, PrintError => 1};
my $dbh = DBI->connect("dbi:SQLite:dbname=$SQLPATH", "", "", $dbargs);

#
# Logic may start here
#

mylog("start $0 --url $url");

# Request url
my $ua = LWP::UserAgent->new;
$ua->agent("Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36");
my $req = HTTP::Request->new(GET => $url);
my $result = $ua->request($req);

if ($result->is_success) {
	my $xml = XML::Simple->new;
	$xml = XMLin($result->content);

	foreach my $item (@{$xml->{channel}->{item}}) {
		my $title = $item->{title};
		my $link = $item->{link};
		my $description = $item->{description};

		my $md5title = md5_hex(encode_utf8($title));

		my $sth = $dbh->prepare("SELECT id FROM data WHERE md5title = ? ");
		$sth->execute($md5title);

		my $ref = $sth->fetchrow_hashref();
	  my $id = $ref->{'id'};

		if (!$id) {
			mylog("new item -> $title");

			# remove html from description
			$description =~ s/(<[^>]*>|;amp|\&amp|;quot|;lt|;gt|;apos|quot;|\&nbsp;)//g;
			# title max 100 characters
			$title = substr $title, 0, 99;

			# send item to pushover
			my $response = LWP::UserAgent->new()->post(
				"https://api.pushover.net/1/messages.json", [
				"token" => $PUSH_TOKEN,
				"user" => $PUSH_USER,
				"message" => $description,
				"title" => $title,
				"url" => $link,
				"url_title" => $title
			]);
			#print Dumper($response);

			if ($response->is_success) {
				# insert in database
				my $update = $dbh->prepare("INSERT INTO data(title,md5title,link,description) VALUES(?,?,?,?)");
				$update->execute($title,$md5title,$link,$description);

			} else {
				my $error = $response->code;
				mylog("could not push message error: $error title: $title");
			}

		}
	} 

	# database maintenance
	$dbh->do("DELETE FROM data WHERE timestamp <= date('now','-30 day');");

} else {
	mylog("Could not receive $url");
}



$dbh->disconnect; 



