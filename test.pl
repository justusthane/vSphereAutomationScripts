#!/bin/perl
use feature 'signatures';
$script_dest = '/root/testdir';
$systemd_dest = '/etc/systemd/system';
mkdir $script_dest if (! -d $script_dest);
chdir "scripts";

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
