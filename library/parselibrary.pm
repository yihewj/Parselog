package ParseLibrary;
use strict;
use warnings;
use Exporter qw(import);

our @EXPORT_OK = qw(isValidDate isValidTime);


sub isValidDate {
    my $date = $_[0];
    if ($date  =~ /[0-1][0-9]-[0-3][0-9]/) {
        return 1;
    } else {
        return 0;
    }    
}

sub isValidTime {
    my $time = $_[0];
    if ($time =~ /^[0-2][0-9]:[0-5][0-9]:[0-5][0-9]/){
        return 1;
    } else {
        return 0;
    }
}



1;