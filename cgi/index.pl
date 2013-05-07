#!/usr/bin/env perl
use CGI::Carp qw(fatalsToBrowser);
use strict;
use warnings;
use Config::File;
use HTML::Template;
use lib 'lib';
use IrcLog qw(get_dbh);
use IrcLog::WWW qw(http_header);

use Cache::FileCache;

print http_header();
my $conf = Config::File::read_config_file('cgi.conf');

if ($conf->{NO_CACHE}) {
    print get_index();
} else {
    my $cache = new Cache::FileCache( { 
            namespace 		=> 'irclog',
            } );

    my $data = $cache->get('index');
    if ( ! defined $data){
        $data = get_index();
        $cache->set('index', $data, '5 hours');
    }
    print $data;
}

sub get_index {

	my $dbh = get_dbh();

	my $base_url = $conf->{BASE_URL} || q{/irclog/};

	my $sth = $dbh->prepare("SELECT DISTINCT channel FROM irclog");
	$sth->execute();

	my @channels;

	while (my @row = $sth->fetchrow_array()){
		next unless $row[0] =~ s/^\#+//;
		my %data = (channel => $row[0]);
		if ($conf->{ACTIVITY_IMAGES}) {
			my $filename = $row[0];
			$filename =~ s/[^\w-]+//g;
			$filename = "images/index/$filename.png";
			$data{image_path} = $filename if -e $filename;
		}
		push @channels, \%data;
	}

	my $template = HTML::Template->new(
			filename => 'template/index.tmpl',
			loop_context_vars   => 1,
			global_vars         => 1,
            die_on_bad_params   => 0,
    );
	$template->param(BASE_URL => $base_url);
	$template->param(HAS_IMAGES => $conf->{ACTIVITY_IMAGES});
	$template->param( channels => \@channels );


	return $template->output;
}
# vim: ft=perl noexpandtab sw=4 ts=4
