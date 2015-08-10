package androidradio;
###!!!!!!!!!!!!!!!!!!put C:\Perl\site\lib!!!!!
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);
use Exporter qw(import);
use constant {
        true => 1,
        false => 0,
};

our @EXPORT_OK = qw(getDataRadioTech getNetworkMode keepOrignal getDataRegState getRilRadioTech getVoiceRegState);

my @dataradiotech = ("Unknown","GPRS","EDGE","UMTS","CDMA-IS95A","CDMA-IS95B","1xRTT","EvDo-rev.0",
                    "EvDo-rev.A","HSDPA","HSUPA","HSPA","EvDo-rev.B","eHRPD","LTE","HSPAP","GSM");
                    
my @dataregstate =( "Not register and not searching", "Registered to home network", "not registered and searching",
                     "registration denied", "Unknown", "Registered, roaming");
                    
my @networkmode =(  "PREF_NET_TYPE_GSM_WCDMA",
                    "PREF_NET_TYPE_GSM_ONLY",
                    "PREF_NET_TYPE_WCDMA",
                    "PREF_NET_TYPE_GSM_WCDMA_AUTO",
                    "PREF_NET_TYPE_CDMA_EVDO_AUTO",
                    "PREF_NET_TYPE_CDMA_ONLY",
                    "PREF_NET_TYPE_EVDO_ONLY",
                    "PREF_NET_TYPE_GSM_WCDMA_CDMA_EVDO_AUTO",
                    "PREF_NET_TYPE_LTE_CDMA_EVDO",
                    "PREF_NET_TYPE_LTE_GSM_WCDMA",
                    "PREF_NET_TYPE_LTE_CMDA_EVDO_GSM_WCDMA",
                    "PREF_NET_TYPE_LTE_ONLY",
                    "PREF_NET_TYPE_LTE_WCDMA"
                    );                    
my @rilradiotech = ( "RADIO_TECH_UNKNOWN",
                    "RADIO_TECH_GPRS",
                    "RADIO_TECH_EDGE",
                    "RADIO_TECH_UMTS",
                    "RADIO_TECH_IS95A",
                    "RADIO_TECH_IS95B",
                    "RADIO_TECH_1xRTT",
                    "RADIO_TECH_EVDO_0",
                    "RADIO_TECH_EVDO_A",
                    "RADIO_TECH_HSDPA",
                    "RADIO_TECH_HSUPA",
                    "RADIO_TECH_HSPA",
                    "RADIO_TECH_EVDO_B",
                    "RADIO_TECH_EHRPD",
                    "RADIO_TECH_LTE",
                    "RADIO_TECH_HSPAP",
                    "RADIO_TECH_GSM",
                    "RADIO_TECH_TD_SCDMA"
                    );
                    

sub getStore{
}
                    
sub getDataRegState {
    my $state = $_[0];
    if (looks_like_number($state) != true) {
        return $state;
    }      
    if ($state <@dataregstate and $state>=0) {
        return $state. "(".$dataregstate[$state].")";
    } else {
        return "dataregstate error";
    }
}   

sub getVoiceRegState {
    my $state = $_[0];
    if (looks_like_number($state) != true) {
        return $state;
    }    
    if ($state == 10){
        return $state. "Not registered, emergency call enabled";
    } elsif ($state == 12){
        return $state. "Not registered but searching, emergency call enabled";
    } elsif ($state == 13){
        return $state."Registration denied";
    } elsif ($state <@dataregstate and $state>=0) {
        return $state. "(".$dataregstate[$state].")";
    }
}                 
                    
sub getDataRadioTech {
    my $tech = $_[0];
    if ($tech < @dataradiotech and $tech >= 0) {
        return $tech."(".$dataradiotech[$tech].")";
    } else {
        return "getDataRadioTech Error";
    }
}


sub getRilRadioTech {
    my $tech = $_[0];
    if (looks_like_number($tech) != true) {
        return $tech;
    }
    my $result;
    
    
    if ($tech < @rilradiotech and $tech >= 0) {
        #return "rilradiotech Error";
        $result = $tech."(".$rilradiotech[$tech].")";
    } else {
        $result = "rilradiotech Error";
    }
    if ($tech == 0) {
        $result = $result."{color}:red";
    }
    return $result;
}

sub getNetworkMode {
    my $mode = $_[0];
    if (looks_like_number($mode) != true) {
        return $mode;
    }    
    if ($mode < @networkmode and $mode >= 0) {
        return $mode."(".$networkmode[$mode].")";
    } else {
        return "getNetworkMode Error. Mode ".$mode;
    }
}

sub keepOrignal {
    return $_[0];
}


1
