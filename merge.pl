#!/usr/bin/perl
#use strict;
#Yi He 2015-10-09
use warnings;
###The real file of these library are in c:\perl\site\lib not the local one!!!!!!!!!!!!!
use ParseLibrary qw(isValidTime isValidDate);

use Scalar::Util qw(looks_like_number);
use PriorityQueue qw(new delete pop insert);
use POSIX;
use Symbol;
#use Hash::PriorityQueue;

my $dbgfh; 
my $dbgfile = "debugfile";
open ( $dbgfh, '>' ,$dbgfile) or die "Could not open $dbgfile: $!";

use constant {
        true => 1,
        false => 0,
        TWENTYMONTH => 2009154623271, 
        ONEDAY => 1000001089,
        DEBUG_ON => undef,
};

sub CreateMergeFileList {
    my $fileName = $_[0];    
    my @fileList = ();
    open (my $fileListHandle, '<', $fileName) or die "Could not open $fileName: $!";
    while (<$fileListHandle>) { 
        s/\r\n\z\t//;
        push (@fileList, $_);
    }
    
    close $fileListHandle;
    return @fileList;
}
#09:55:01.370-09-29
#"11:56:41, 11/22/2011";
sub toCompareable{
    my ($date) = @_;
    my ($H,$M,$S,$MS,$m,$d) = $date =~ m{^([0-9]{2}):([0-9]{2}):([0-9]{2}).([0-9]{3})-([0-9]{2})-([0-9]{2})\z}
      or die;
   return "$m$d$H$M$S$MS";
}


sub GetLogTime {
    my ($line) = $_[0];
    my $time = "";
    my $startind = 0;
    my $endind = index($line," ");    
    my $logday = substr($line, $startind, $endind);
    $line = substr($line, $endind+1);
    if (isValidDate  ($logday) == true) {
        $date = $logday;
    } else {
        return undef;
    } 
    $endind = index($line," ");
    my $logtime = substr($line, $startind, $endind);
    if (isValidTime  ($logtime) == 1) {
        $time = $logtime;
    } else {
        return undef; 
    }    
    my  $comparetime =  toCompareable($time."-".$date);
    return $comparetime;
}

#if (!defined $pname) {
sub MergeAndOutputFiles{
    my @fileList = @{$_[1]};;
    my $outputfilename = $_[0];
    my @fileHandle = ();
    my $outputfh;
    open($outputfh, '>', $outputfilename) or die "Could not open file '$outputfilename' $!";
    
    
    foreach $fileName (@fileList) {
        $fileName =~ s/[\x0A\x0D]//g; 
        print $fileName." ";
        my $fh = gensym;
        open ($fh, '<', $fileName) or die "Could not open $fileName: $!";
        push(@fileHandle, $fh);       
    }
    
   my $len = @fileHandle;
  # my $fh = $fileHandle[0]; //For test
   my $fh;
   my $date;
   my $time;
   my $fhnum = @fileHandle;
   my @linearr = @fileHandle;
   my $logQueue = PriorityQueue->new();
   for (my $i = 0; $i < $fhnum; $i++) {
     $fh = $fileHandle[$i];
     if (eof $fh) {
        next;
     }
     $linearr[$i] = <$fh>;
     my $logtime = GetLogTime($linearr[$i]);

     while (!defined $logtime) {
        #Output
        if (eof $fh) {           
            last;
        }
        $linearr[$i] = <$fh>;
        $logtime = GetLogTime($linearr[$i]);
     } 

     if (defined $logtime) {
        $logQueue->insert($i, $logtime); 
     }
   }
   
   my ($outIndex, $outtime) = $logQueue->pop();
   
   my $nextfhind = undef;
   
   #timezone change.. Sometimes timezone change and the time backwards. So need consider the situation. 
   
   while (defined $outIndex)  { #Queue isnot empty
          print $outputfh $linearr[$outIndex];
          $fh = $fileHandle[$outIndex];
          if (eof $fh) {
            if (defined DEBUG_ON) {
                print  $dbgfh "\n End of file ".$fileList[$outIndex]."\n";
            }
            ($outIndex, $outtime) = $logQueue->pop();
            next;
         }
         $linearr[$outIndex] = <$fh>;
         my $logtime = GetLogTime($linearr[$outIndex]);
         my $index = undef;
         my $tmpOuttime = undef;
         #outtime is large than TWENTYMONTH, it means all logs reach time zone change point.
         if ((defined $outtime) && ($outtime > TWENTYMONTH)) {
             if (defined DEBUG_ON) {
                print $dbgfh "Start unblock change logs \n";
             }
             $outtime = $outtime - TWENTYMONTH;
             #Need update all data in the queue
            ($tmpindex, $tmpOuttime) = $logQueue->pop();
            my @tmpIndxLst =();
            my @tmpTime = ();
            my $updateLen = 0;
            while (defined $tmpindex) {
                push @tmpIndxLst, $tmpindex;
                $tmpOuttime = $tmpOuttime - TWENTYMONTH;
                push @tmpTimeLst, $tmpOuttime;
                $updateLen++;
                ($tmpindex, $tmpOuttime) = $logQueue->pop();
            } 
           for (my $i = 0; $i < $updateLen; $i++) {
               $logQueue->insert($tmpIndxLst[$i], $tmpTimeLst[$i]);
           
           }         
         }  
         #Time zone update end          
         #Just output consecuive log if the timestamp is same in same file. Don't need to enqueue to improve performance.
         while (!defined $logtime || ((defined $outtime) && ($logtime eq $outtime))) {     
            if (eof $fh) {
                last;
            }
            print $outputfh $linearr[$outIndex];  #If it isn't log line with correct time, just output it
            $linearr[$outIndex] = <$fh>;
            $logtime = GetLogTime($linearr[$outIndex]);
         } # end of same time handle
         if (defined $logtime)
         {
             print ".";
             print $dbgfh "push "." ".$fileList[$outIndex]. " ". $outIndex." ".$logtime." ";
             #need handle timezone change. Use hack methods, Not all logs are in sequence. Some of them just backward xxx ms. S
             #So use 1999 means 1999 ms to distinguish timezone change. Timezone change shouldn't large than 1 day. So use 1000001089 
             if ($logtime < $outtime && ($outtime - $logtime) < 1000001089 && ($outtime - $logtime >1999)) {                 
                $logtime = $logtime + TWENTYMONTH;  #BLOCK the log which have timezone change. Wait for all logs reach TIMEZONE change.
                if (defined DEBUG_ON) {
                    print $dbgfh "\nTime backward: ".$logtime." ".$outtime."\n";
                    print $dbgfh $linearr[$outIndex];
                }
             }
             $logQueue->insert($outIndex, $logtime);
         }
         
         ($outIndex, $outtime) = $logQueue->pop();
     }
    
    foreach my $fh (@fileHandle) {
        close $fh;
    }
    
   
    close $outputfh;
    
}

my $OutFile = "Merge.txt";



if (@ARGV < 1) {
    print "Need input the logname storage file\n";
}else {    
    my @FileList = CreateMergeFileList($ARGV[0]);
    MergeAndOutputFiles($OutFile, \@FileList);
}

close $dbgfh;



