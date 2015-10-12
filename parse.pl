#!/usr/bin/perl
#use strict;
use warnings;
###The real file of these library are in c:\perl\site\lib not the local one!!!!!!!!!!!!!
use ParseLibrary qw(isValidTime isValidDate);
use androidradio qw(getSetupDataCallRadioTech getRSRP getRSRQ getSINR getCMReportName processSIPMessage 
                    getSysSrvStatus getSysMode getVoIPCallEndReason getDataRadioTech 
                    getNetworkMode keepOrignal getDataRegState getRilRadioTech getVoiceRegState);
use qmifailure qw(getCallQMIFailedCause);
use Scalar::Util qw(looks_like_number);
use POSIX;


my @keywordfile = (

                    );
            
my $time=" ";
my $date=" ";
my @arry=("UMTS","LTE");

my $keychar = "\$";
my $blankchar = " ";

my @data =();
my @keywordlist=();
my $kwkey = "\%\%";
my @keyfunclist =();
my @keywordmap=();
my @keyfuncmap=();
my @rawoperationmap=();
my @lastStatement = @keywordfile;
my $outhandle;
my $outname = "output.html";
my $fh;
my $colorkeychar ="{color}:";
my @keepdup = ();
my $dupkeychar = "{keepdup}";
my $ignoreBlank = "{ignoreblank}";
my $dummyKeyword = "\@\-\@";

use constant {
        true => 1,
        false => 0,
};
my $skipdup = true;

sub outputHandle {
    #my $formatStr = $_[0]; 
    #print $_[0]."\n";
    my $statement ="";
    my($strwithoutdup, $dup) = getAndRemoveDupKey($_[0]);
    my($strwithoutcolor, $color) = getAndRemoveColor($strwithoutdup);
    my($formatStr, $ignoreBlank) = getAndRemoveignoreBlank($strwithoutcolor);
    
    my $len = length($formatStr);
    my $start = 0;
   # my $hlcolor = "";
    #print $formatStr."\n";
    
    my $index = index($formatStr, $keychar);
    if ($index == -1) {
        $statement = $formatStr;
           # print $formatStr . "\n"; # return remain data
    }   
    my $j = 0;
    my $i = $_[1];
    if (length($color)!=0) {
        $fontformat = '<font face="Courier New" size="3" color="'.$color.'">';
        printtofile($fontformat);
    }
    
    my $blankResult = false;
    my $convertdata =  "";
    
    while ($index != -1) {  
        my $word;
        if ($index == 0) {
            my $endindex = index($formatStr, $blankchar);
            $word = substr($formatStr, 1, $endindex);            
            $formatStr = substr($formatStr, $endindex);               
            
        } else {
            $word = substr($formatStr, 0, $index);            
            $formatStr = substr($formatStr, $index);                  
        }
       # print "\n"."Word: " .$word."\n";
       # print "formatStr: ".$formatStr."\n";
        #$word  =~ s/\s//g;
        # print "\n"."Word: " .$word."\n";
        if (looks_like_number($word)) {     
            my $keycolor ="";
            ($convertdata,$blankResult) = getAndRemoveDummyKeyWord($data[$word-1]);
             #print $convertdata."----\n";   
             
            ($convertdata, $keycolor) = getAndRemoveColor($convertdata);
            #print $statement."\n";
            if (length($keycolor) != 0) {
                $convertdata = '<font face="Courier New" size="3" color="'.$keycolor.'">'.$convertdata."</font>";
            }
            $statement = $statement.$convertdata;
            #print $data[$word-1];#." ";
        } else {
            $statement = $statement.$word;
            #print $word;# ";
        }
        $index = index($formatStr, $keychar);
        if ($index == -1 ) {
            #print "--".$formatStr . "\n"; # return remain data
            
            if (looks_like_number($formatStr)) {
               # my $tmp = $data[$formatStr-1];
               # $tmp =~ s/\r|\n//g;
                ($convertdata,$blankResult) = getAndRemoveDummyKeyWord($data[$word-1]);
                my $keycolor ="";
                ($convertdata, $keycolor) = getAndRemoveColor($convertdata);
                if (length($keycolor) != 0) {
                    $convertdata = '<font face="Courier New" size="3" color="'.$keycolor.'">'.$convertdata."</font>";
                }
                $statement = $statement.$convertdata;
                #print $data[$formatStr-1];
                #print $keyfuncmap[$i][$j]->($formatStr);
            } else {
                $statement = $statement.$formatStr;
                #print $formatStr;
            }   
        }  
        $j = $j+1;
    }
   # print "skip dup :".$skipdup." dup: ".$dup."\n";
   if ($ignoreBlank == true && $blankResult == true) {
        return;
   }
    if($skipdup && ($dup == 0)) {
        if ($i >= @lastStatement || length($lastStatement[$i])==0 || $lastStatement[$i] ne $statement) {
          printtofile("<br>");
          printtofile($time." ");
          printtofile($statement);
          printtofile("\n");
          #print $statement."\n";
         
        }
    } else {
      #  print $time."  ";
     # print $statement."\n";
      printtofile("<br>");
      printtofile($time." ");
      printtofile($statement);
     # printtofile("\n");

    }
    if (length($color)!=0) {        
        printtofile("</font>");
    }
    
    $lastStatement[$i] = $statement;
}



sub keywordhandle {
    my $rawkey = $_[0];  
    #$rawkey = $line =~ s/\r|\n//g;
    my $ind = index($rawkey, $kwkey);
    #print "Rawkey:".$rawkey." Kwkey:".$kwkey."\n";
    my $start = 0;
    $#keywordlist  = -1;
    $#keyfunclist = -1;
    while ($ind != -1) {
        my $nextind;
        if ($ind == 0) {
            $nextind = index($rawkey, $kwkey, $ind+2);
            my $function = substr($rawkey, $ind+2, $nextind);
            #print "Functions: ".$function."\n";
            push(@keyfunclist, $function);         
        } else {
            my $keys = substr($rawkey, $start, $ind-$start);  
            #print $keys."\$\n";
            push(@keywordlist, $keys);           
            $nextind = index($rawkey, $kwkey, $ind+2);
            my $function = substr($rawkey, $ind+2, $nextind-$ind-2);     
            #print "Functions: ".$function."\n";            
            push(@keyfunclist, $function);            
        }
        $rawkey = substr($rawkey, $nextind+2);
        $ind = index($rawkey, $kwkey);
        if ($ind == -1) {
            $rawkey =~ s/\s+$//;
           #print "rawkey ". $rawkey."\n";
            if (length($rawkey)!= 0) 
            {
                #print  $rawkey."\$\n";
                #if ($rawkey =~ /^\s +$/) {
                    push(@keywordlist, $rawkey);  
               # }
            }
        }
    } 
    #printArray(@keywordlist);
    push(@keywordmap,[@keywordlist]);
    push(@keyfuncmap,[@keyfunclist]);
}
       # my %actions = ( 
       #                outhandle =>\&outputHandle ,
       #               );
                       
       #$actions{'outhandle'}->("This", "Pig");               
       # outputHandle($rawoperation);
sub dbgPrintArray {
    my @testarray = $_[0];
    
    foreach (@testarray)  {
         my $keyword = $_;
         print "Keyword is :".$keyword."\n";         
    }
}     
sub inithandlemap {
    foreach (@keywordfile) {
        my $keyword = $_;
        if (length($keyword) == 0) {
            next;
        }
        #$keyword =~ s/\r|\n//g;
        my ($condition) = $keyword =~/(.*)\@->/x;
        #print "Condition:".$condition."\n";
        my ($rawoperation) = $keyword =~/\@->(.*)/x;
       # print $rawoperation."\n";
        keywordhandle($condition);
        push(@rawoperationmap, $rawoperation);
    }
}

sub radiohandle {
    my $line = $_[0];
    my $hasfound = 0;
    my $j = 0;
    my $foundline = -1;
    my $len = $#keywordmap;
    $#data = -1;
    for my $i (0..$len) {   
        my $linelen = $#{$keywordmap[$i]};
        for $j (0..$#{$keywordmap[$i]}) {
        
            my $k = $keywordmap[$i][$j];
           # print "line :".$line."\n";
            #print "keyword :". $k."\n";
            my $pos = index ($line, $k);
            if ($pos != -1){
                $hasfound = 1;
                $foundline = $i;
             #   print "Has found"."\n";
            } else {
                $hasfound = 0;
                
                last;
            }
            
        }
        if ($hasfound == 1) {   
            last;
        }
    }    
        
    if ($hasfound == 0) {
        return;
    }
    

    
    #print $line."\n";
    my $startind = 0;
    my $endind = index($line," ");    
    my $logday = substr($line, $startind, $endind);
    $line = substr($line, $endind+1);
    if (isValidDate  ($logday) == 1) {
        $date = $logday;
    }
    $endind = index($line," ");
    my $logtime = substr($line, $startind, $endind);
    if (isValidTime  ($logtime) == 1) {
        $time = $logtime;
    }  
    
    #print $time."  ";
    my $index = 0;
    my $prepos = 0;
    my $length = length($line);
    my $numreplacevar = 0;
    #print "Total line is: ".$#{$keywordmap[$foundline]}."\n";
    for $j (0..$#{$keywordmap[$foundline]}) {
       $index = index ($line, $keywordmap[$foundline][$j], $prepos);
       my $kwlen = length($keywordmap[$foundline][$j]);
       #print "keyword:". $keywordmap[$foundline][$j]." index:".$index." kwlen:".$kwlen."\n";       
       if ($prepos != 0) {
            my $data = substr($line, $prepos, $index-$prepos);       
            #print "1Data: ".$data."\n";        
            push(@data, $keyfuncmap[$foundline][$j-1]->($data));
            $numreplacevar++;
            
       }     
       $prepos = $index + $kwlen;     
       
    }
    

    my $matchnum = () = ($rawoperationmap[$foundline] =~ /\$/g);
    #$j = $j+1;
   # my $matchnum =  ($rawoperationmap[$foundline] =~ tr/$keychar//);
   # print "operaton map:".$rawoperationmap[$foundline]."\n";
    #print "matchnum:".$matchnum." prepos".$prepos." length:".$length." numreplace:".$numreplacevar."\n";
    if ($prepos != $length ){#&& $matchnum > $numreplacevar) {
        
        my $data = substr($line, $prepos, $length-$prepos);
        #print "j =".$j."\n";
        my $str = $keyfuncmap[$foundline][$#{$keyfuncmap[$foundline]}]->($data);
      
       # print "2Data: ".$data."\n";   
        push(@data, $str);
        
    }
    
    outputHandle($rawoperationmap[$foundline], $foundline);  
}

sub HandlelogFile {
    binmode(STDOUT);
    my $file = $_[0];

    open (my $info, '<', $file) or die "Could not open $file: $!";
    while (<$info>) { 
        s/\r\n\z//;
        #print "$_\n";
        print ".";
        radiohandle($_);
    }
    close $info;
}
sub CreateConfig{
    my $file = $_[0];
    #local $/ = "\r";
    open my $info, $file or die "Could not open $file: $!";
    @keywordfile =();
    #@keywordfile = <$info>;
    while(my $line = <$info>) {
        if (index($line, "\#") != 0) {
            push (@keywordfile, $line);
        }
    }
    #print "file length:".@keywordfile."\n";
   # foreach(@keywordfile) {
    #   print $_;
    #}
    @lastStatement = @keywordfile;
    close $info;
}

sub header {
my $title = $_[0];
return qq{<HTML>\n<HEAD>\n<title>$title</title></head>};
}

##Some line we do want to duplicate there
sub getAndRemoveDupKey {
    my $input = $_[0];    

    my $start = index($input,$dupkeychar);
    if ($start == -1) {
        return ($input,"0");
    }
    my $len = length($input);
    $input = substr($input, 0,$start).substr($input,$start+length($dupkeychar),$len-1);

    return ($input, "1");

}

sub getAndRemoveDummyKeyWord {
    my $input = $_[0];    

    my $start = index($input,$dummyKeyword);
    if ($start == -1) {
        return ($input,"0");
    }
    my $len = length($input);
    $input = substr($input, 0,$start).substr($input,$start+length($dummyKeyword),$len-1);

    return ($input, "1");
}


sub getAndRemoveignoreBlank {
    my $input = $_[0];    

    my $start = index($input,$ignoreBlank);
    if ($start == -1) {
        return ($input,"0");
    }
    my $len = length($input);
    $input = substr($input, 0,$start).substr($input,$start+length($ignoreBlank),$len-1);

    return ($input, "1");
}


sub getAndRemoveColor {

    my $input = $_[0];    

    my $start = index($input,$colorkeychar);
    
    if ($start == -1) {
        return ($input,"");
    }
    my $rmkeystr;
    my $color;
    my $end = index($input, " ",$start);
    if ($end == -1) {
        $color = substr($input, $start+length($colorkeychar), 
                        length($input) - $start-length($colorkeychar));
        $rmkeystr = substr($input, 0, $start);        
    } else {
        $color = substr($input, $start+length($colorkeychar), $end - $start-length($colorkeychar));
        my $firststr = substr($input, 0, $start);
        my $endstr = substr($input, $end+1, length($input)-$end-1);
        $rmkeystr = $firststr.$endstr;
    }

   # print "After change:".$rmkeystr."tt\n";
   # print "Return word:".$color."tt";
    #return {$rmkeystr, $color};
    return ($rmkeystr, $color);
}


#radiohandle ("09-24 16:03:53.127 D/PHONE   ( 1354): [ServiceState] setDataRadioTechnology=15");



my @values = split(/\\/, $ARGV[0]);
my $last = @values;
$outname =  $values[$last-1].$outname;
print $outname."\n";
open($fh, '>', $outname) or die "Could not open file '$outname' $!";

sub printtofile {
    print $fh $_[0];
}
#printtofile("Content-Type: text/html");
#printtofile ("Log Analysis Result");

printtofile("<HTML>");
printtofile("<BODY>");
#printtofile('<font face="Courier New" size="2" color="gray">');

if (@ARGV < 1) {
    print "Need input log file name\n";
} elsif (@ARGV < 2){  
    inithandlemap();  
    printtofile(":".$ARGV[1]);
    HandlelogFile($ARGV[0]);
    
}else {    
    
    CreateConfig($ARGV[0]);
    inithandlemap();
    printtofile($ARGV[1]);
    HandlelogFile($ARGV[1]);
}
printtofile('</font>');
printtofile("</BODY>");
printtofile("</HTML>");
close $fh;
system ("start ".$outname);

