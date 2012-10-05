#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Crontab::Stats;
use Data::Dumper;

#Crontab object
my $stats = Crontab::Stats->new();

#Set the path
$stats->setPath('/home/bhill/git/rp_crontabs_utils');

#$stats->setFileList(qw/brady jeney/);
#my @stats = $stats->getFileList();

#print join(',',@stats);


#$stats->fileLineStats('/home/bhill/git/rp_crontabs_utils/sscertified/tools.sscertified.cron');
#$stats->fileLineStats('/home/bhill/git/rp_crontabs_utils/root/w3clia-d2.root.cron');

$stats->groupLineStats($stats->getPath());


#my $files = $stats->getAllFiles($stats->getPath());

#my $removeDir = $stats->removeDirectory($files);

#my $recurseDirs = $stats->recurseDirs($stats->getPath());

$stats->validateCronTime($stats->getPath());

print Dumper($stats);


#print Dumper($files);
#print Dumper($removeDir);
#print Dumper($recurseDirs);


exit;
