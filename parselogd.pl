#use strict;
use warnings;
use File::Basename;
use Cwd;
use File::Spec;
use Scalar::Util qw(looks_like_number);
use Compress::Raw::Bzip2;
use ParseLibrary qw(isValidTime isValidDate);
use File::ReadBackwards;
use IO::Uncompress::Unzip qw(unzip $UnzipError) ;
use ParseLibrary qw(isValidTime isValidDate);
use Scalar::Util qw(looks_like_number);
use PriorityQueue qw(new delete pop insert);

use constant {
        true => 1,
        false => 0,
        distinct => 3,
};

my $outfh;

sub printtofile {
    print $outfh $_[0];
}

my $outputfile = "output.html";

sub printlog {
    print "!!!Log:".$_[0]."\n";
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
    my $date = undef;
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
    
    
    foreach my $fileName (@fileList) {
        $fileName =~ s/[\x0A\x0D]//g; 
        print $fileName." | ";
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
        print "Push ".$i."\n";
        $logQueue->insert($i, $logtime); 
     }
   }
   
   my ($outIndex, $outtime) = $logQueue->pop();
   
   while (defined $outIndex)  { #Queue isnot empty
      #Output $linearr[$outIndex];
 #     print $outIndex."!!!";
      print $outputfh $linearr[$outIndex];
      $fh = $fileHandle[$outIndex];
      if (eof $fh) {
        $outIndex = $logQueue->pop();
        next;
     }
     $linearr[$outIndex] = <$fh>;
     my $logtime = GetLogTime($linearr[$outIndex]);
        while (!defined $logtime || ((defined $outtime) && ($logtime eq $outtime))) {
        #while (!defined $logtime ) {
            #Output        
            if (eof $fh) {
                last;
            }
            print $outputfh $linearr[$outIndex];  #If it isn't log line with correct time, just output it
            $linearr[$outIndex] = <$fh>;
            $logtime = GetLogTime($linearr[$outIndex]);
         }
         if (defined $logtime)
         {
             print ".";
             $logQueue->insert($outIndex, $logtime);
         }
         
         ($outIndex, $outtime) = $logQueue->pop();
     }
    
    foreach my $fh (@fileHandle) {
        close $fh;
    }

    close $outputfh;    
    
}


sub getDistNumBtwStr {
    my $str1 = $_[0];
    my $str2 = $_[1];
    
    my $len1 = length($str1);
    my $len2 = length($str2);
    my $num = ($len1 > $len2)?($len1 - $len2):($len2 - $len1);
    my $len = ($len1 > $len2)?$len2:$len1;
    my @chars1 = split("", $str1);
    my @chars2 = split("", $str2);
    my $sharefilename = "";
    for (my $i = 0; $i < $len; $i++) {
        if ($chars1[$i] ne $chars2[$i]) {
            $num++;
        } else {
           $sharefilename = $sharefilename.$chars1[$i]; 
        }
    }
    return ($num,$sharefilename);
}

sub ProcessDirectory
{

   my $input_dir = $_[0];
   my $distinct = distinct;

   if(not -d $input_dir)
   {
      print "\nThis script requires that the directory \"$input_dir\" exist and contain at least one \".dlf\" file.\n";
      exit(1);
   }
   else
   {
      print "Input Directory: \"$input_dir\"\n";
   }  
   
   if( -d "temp" )
   {
     my $command ="del temp /Q";
     system($command);
   }
   
   my $currentDir = getcwd();
   chdir($input_dir);  
   
   my @files = <*.gz>;
   
   printtofile("<HTML>");
   printtofile("<BODY>");
   

   my $filenum = @files;

   for (my $i = 0; $i < $filenum; $i++)
   {
   
   
      my $file_name = $files[$i];
      ProcessSingleFile($input_dir,$file_name);
      print "  Done.\n";         
        
   }
   MergeLog($input_dir."\\temp");
   chdir($currentDir);  
   printtofile("</BODY>");
   printtofile("</HTML>");
}

sub MergeLog {
   my $input_dir = $_[0];
   my $currentDir = getcwd();
   chdir($input_dir);
   my @files = <*.txt>;
   my $filenum = @files;
   my $i = 0;
   my $candidatestartFileName = undef;
   my $mergeoutputFilename = undef;
   my @mergeFileList = ();
   my ($diff, $candidatecommonFilename);
   for ($i = 0; $i < $filenum; $i++) {
        my $file_name = $files[$i];
        if (!defined $candidatestartFileName) {
            $candidatestartFileName = $file_name;
            push (@mergeFileList, $candidatestartFileName);
        } else {
            ($diff, $candidatecommonFilename) = getDistNumBtwStr($candidatestartFileName, $file_name);
            if ($diff < 2 && ($i != ($filenum -1)) ) {
                if (!defined $mergeoutputFilename) { #create output file
                    $mergeoutputFilename = "merge_".$candidatecommonFilename;
                    $candidatestartFileName = $file_name;
                }       
                push (@mergeFileList, $file_name); #Add merge file if just differnt type.
            } else {
                if ($i == ($filenum -1)) { #We need handle last one speically
                    push (@mergeFileList, $file_name);  #Add last file
                    
                }
                if (defined $mergeoutputFilename) { #output all list
                  #  printtofile '<br>'.'<font face="Courier New" size="3" color="blue">'."Merge output File:".$mergeoutputFilename;
                  #  my $size = @mergeFileList;
                  #  for (my $i = 0; $i < $size; $i++) {
                  #      printtofile '<br>'.'<font face="Courier New" size="2" color="blue">'."Input File:".$mergeFileList[$i];
                  #  }
                  print "\nStart to Merge..... \n";
                  MergeAndOutputFiles($mergeoutputFilename, \@mergeFileList);

                }            
                $candidatestartFileName = $file_name; 
                @mergeFileList=();
                push (@mergeFileList, $candidatestartFileName);  
                $mergeoutputFilename = undef;  
            }  
        }           
     
     }
   
   
   chdir($currentDir); 
}


 #  print $first."\n";
# $status = $bz->bzinflate($filename, "temp");

sub ProcessSingleFile
{
    my $filename = "$_[0]\\$_[1]";
    my $command = "7z "." e "."\"$filename\""." -otemp";
    print $command."\n";
    system($command);
   # unzip $filename => "\"temp".$filename.".txt\""
   #     or die "unzip failed: $UnzipError\n";
    my $unzipfilename = substr($filename, 0, -3);
    my $fh;
    open($fh, '<', "temp\\".$unzipfilename) or die "Could not open file 'temp\\'.$unzipfilename $!";
    my $starttime = undef;
    while (!eof $fh) {
        my $firstline = <$fh>;
        $starttime = GetLogTime ($firstline);
        if (defined $starttime) {
            last;
        }
    }    
    
 
     close($fh);
     my $bw = File::ReadBackwards->new("temp\\".$unzipfilename,"\x0A");
     my $endtime = undef;
     my $lastline  = $bw->readline;
     while (defined $lastline) {
        $endtime = GetLogTime ($lastline);
        if (defined $endtime) {
            last;
        }
        $lastline  = $bw->readline;
     }

     printtofile '<br>'.'<font face="Courier New" size="3" color="blue">'.$unzipfilename;     
     if (defined $starttime) {
        printtofile ' <font face="Courier New" size="2" color="blue"> Start time: '.$starttime;
     }
     if (defined $endtime) {
         printtofile " End time: ".$endtime;
     }
}




open($outfh, '>', $outputfile) or die "Could not open file '$outputfile' $!";

if ($#ARGV > -1) # if filename is supplied
{

      
   foreach my $file (@ARGV) 
   {
      if( -d $file )
      {
         ProcessDirectory($file);
      }
      elsif( -e $file )
      {
         ProcessSingleFile($file);
      }
      else
      {
         print "\"$file\" is not a vaild file or directory.\n";
      }
   }
}

close $outfh;
system ("start ".$outputfile);
system ("start .");

