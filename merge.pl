#!/usr/bin/perl
#use strict;
#Yi He 2015-09-09
use warnings;
###The real file of these library are in c:\perl\site\lib not the local one!!!!!!!!!!!!!
use ParseLibrary qw(isValidTime isValidDate);

use Scalar::Util qw(looks_like_number);
use PriorityQueue qw(new delete pop insert);
use POSIX;
use Symbol;
#use Hash::PriorityQueue;



use constant {
        true => 1,
        false => 0,
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

sub removeElementFromArray {
    my $index = $_[1];
    my @array = @{$_[0]};;
    my $len = @array;
    my @newarray;
    for (my $i = 0; $i < $index; $i++) {
        push @newarray, $array[$i];
    }
    for (my $i = $index+1; $i < $len; $i++) {
        push @newarray, $array[$i];
    }   
    return @newarray;
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
        print $fileName;
        my $fh = gensym;
        open ($fh, '<', $fileName) or die "Could not open $fileName: $!";
        push(@fileHandle, $fh);       
    }
    
   my $len = @fileHandle;
   print "\nLen:".$len."\n";
  # my $fh = $fileHandle[0]; //For test
   my $fh;
   my $date;
   my $time;
   my $fhnum = @fileHandle;
   my @linearr = @fileHandle;
   $#array = $fhnum;
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
     $logQueue->insert($i, $logtime); 
   }
   
   my $outIndex = $logQueue->pop();
   while (defined $outIndex)  { #Queue isnot empty
      #Output $linearr[$outIndex];
      print $outputfh $linearr[$outIndex];
      $fh = $fileHandle[$outIndex];
      if (eof $fh) {
        $outIndex = $logQueue->pop();
        next;
     }
     $linearr[$outIndex] = <$fh>;
     my $logtime = GetLogTime($linearr[$outIndex]);
     while (!defined $logtime) {
        #Output        
        if (eof $fh) {
            last;
        }
        $linearr[$outIndex] = <$fh>;
        $logtime = GetLogTime($linearr[$outIndex]);
     }
     if (defined $logtime)
     {
         print "Logtime before ". $logtime."\n";
         $logQueue->insert($outIndex, $logtime);
     }
     
     $outIndex = $logQueue->pop();
   }
   
   
   while ($fhnum != 0) {
        for (my $i = 0; $i < $fhnum; $i++) {
            $fh = $fileHandle[$i];
            if (eof $fh) {
                close $fh;
                @fileHandle = removeElementFromArray(\@fileHandle, $i);
                print "Delete one\n";
                $fhnum = $fhnum - 1;
                next;
            }
            $line = <$fh>;
            if ($line =~ /^$/) {
                
            } else {
                print $line; 
            }            
        }  
   }
   print "-------File num:".@fileHandle."\n";
   
   
#  while (true) {
#       if ($line =~ /^$/) {
#            #blank line
#       }
#       else {
#           print $line; 
#           $date = "";
#           $time = "";
#           my $startind = 0;
#           my $endind = index($line," ");    
#           my $logday = substr($line, $startind, $endind);
#           $line = substr($line, $endind+1);
#           if (isValidDate  ($logday) == 1) {
#               $date = $logday;
#           }
#           $endind = index($line," ");
#           my $logtime = substr($line, $startind, $endind);
#           if (isValidTime  ($logtime) == 1) {
#               $time = $logtime;
#           } 
#           if ($date ne "" and $time ne "") {
#              #my $combinetime = $time."-".$date;
#              my  $comparetime =  toCompareable($time."-".$date);
#              # my $comparetime = toCompareable($time."-".$date);
#              # print $comparetime."\n";
#              print $comparetime."\n";
#           }
#           
#       }
#     #  print $date."--".$time."\n";
#      if (eof $fh) {
#          last;
#      }
#      $line = <$fh>;                
#  }

 #  foreach my $fh (@fileHandle) {
 #      my $line = <$fh>;
 #      while (true) {
 #          print $line;  
 #          if (eof $fh) {
 #              last;
 #          }
 #          $line = <$fh>;                
 #      }
 #        
 #  }
    
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



