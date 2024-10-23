#!/bin/perl
use feature 'signatures';
use lib qw(modules/share/perl5/5.32);
use Config::Tiny;
$script_dest = '/root/testdir';
$systemd_dest = '/etc/systemd/system';

$config = Config::Tiny->read('CONFIG.ini');
print($config->{_}->{vsphere_user});

sub foo :lvalue ($x, $y = 0) {
								print "$x\n";
								print "$y\n";
}

sub bar {
								my (%args) = @_;

								my $x = $args{x};
								my $y = $args{y} || 0;

								print "$x\n";
								print "$y\n";
}
foo("Hi", $y=1);
bar(x => "Hi", y => 1);
bar();
