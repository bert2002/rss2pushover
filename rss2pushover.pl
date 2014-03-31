#!/usr/bin/perl
# script: rss reader to pushover.net
# author: Steffen Wirth <s.wirth@itbert.de>
# github: https://github.com/bert2002/rss2pushover

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

my $help;

#
# Config
#

GetOptions (
	'h|help' => \$help
) or exit 1;

if ($help) {
	print "Usage: $0 more @ https://github.com/bert2002/rss2pushover\n";
  exit 0
}

# user configuration
my $DEBUG = "1"; # enable for stdout logging
my $LOGPATH = $ENV{"HOME"} . "/log"; # path to log directory
my $SQLPATH = $ENV{"HOME"} . "/rss2pushover.db"; # Path to sqlite3 database

#
# Helper
#

# logging
mkdir "$LOGPATH/", 0777 unless -d "$LOGPATH";
open (LOGPATH, ">>$LOGPATH/rss2pushover.log") or die "can not open logfile $LOGPATH/rss2pushover.log";
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

# getting channel information
my $sth = $dbh->prepare("SELECT * FROM channel WHERE status = ?");
$sth->execute(1);

while (my $ref = $sth->fetchrow_hashref()) {
	my $channelid = $ref->{'id'};
	my $url = $ref->{'url'};
	my $token = $ref->{'token'};
	my $user = $ref->{'user'};

	mylog("start $0 channel: $channelid");

	# Request url
	my $ua = LWP::UserAgent->new;
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

			my $sth = $dbh->prepare("SELECT id FROM data WHERE md5title = ? AND channel = ?");
			$sth->execute($md5title,$channelid);

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
					"token" => $token,
					"user" => $user,
					"message" => $description,
					"title" => $title,
					"url" => $link,
					"url_title" => $title
				]);
				#print Dumper($response);

				if ($response->is_success) {
					# insert in database
					my $update = $dbh->prepare("INSERT INTO data(title,md5title,link,description,channel) VALUES(?,?,?,?,?)");
					$update->execute($title,$md5title,$link,$description,$channelid);

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
}



$dbh->disconnect; 


