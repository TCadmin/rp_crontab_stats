# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Crontab-Checker.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3; 
use FindBin qw($Bin);
use lib "$Bin/../lib";
BEGIN { use_ok('Crontab::Stats') };
use Crontab::Stats;
use Data::Dumper;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#Crontab object
my $stats = Crontab::Stats->new();

# Test sub setPath
is( $stats->setPath('/home/bhill/git'), '/home/bhill/git');

# Test sub getPath
is( $stats->getPath(),'/home/bhill/git');

exit;
