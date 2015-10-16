package qmifailure;
###The real file is in c:\prel\site\lib. Need update the file in that place as well


use strict;
use warnings;
use Scalar::Util qw(looks_like_number);
use vars qw(@EXPORT_OK);
use Exporter qw(import);
use constant {
        true => 1,
        false => 0,
};

our @EXPORT_OK = qw(getCallQMIFailedCause);

sub getCallQMIFailedCause {
    my $qmicause = $_[0];
    if (looks_like_number($qmicause) != true) {
        return $qmicause;
    }

    if ($qmicause == 25) {
        return "CALL_END_CAUSE_REL_NORMAL_V02";
    } elsif($qmicause == 330){
        return "CALL_END_CAUSE_RTP_RTCP_TIMEOUT_V02";
    } elsif($qmicause == 146){
        return "CALL_END_CAUSE_USER_BUSY_V02";
    }else {
        return $qmicause." Refered to voice_service_common_v02.h ";
    }    

}

1