package ErrorLog;
use strict;
use warnings;
use Time::Local;
use File::Copy;
 
# General Purpose Error Logging Module
# VERSION: 0.1;  see version notes at bottom of file.
 
##################################################
## the object constructor (simplistic version)  ##
##################################################
sub new {
   my $self  = {};
   $self->{log_errors} = undef;
   $self->{log_file} = undef;
   $self->{loghandle} = undef;
   $self->{error_file} = undef;
   $self->{errorhandle} = undef;
   $self->{std_out} = undef;
   $self->{browser_out} = undef;
   $self->{file_out} = undef;
   $self->{backupage} = 1;
   $self->{maxageinseconds} = 604800;
   
   bless($self);
   return $self;
}

sub startLogging {
  my $self = shift;
  $self->{log_errors} = 1;
}

sub stopLogging {
  my $self = shift;
  $self->{log_errors} = 0;
}

sub createLog {
  # get parameters
  my $self = shift;
  my $enable = $_[0];
  my $logfile = $_[1];
  my $errorfile = $_[2];
  my $outputtypes = $_[3];
  
  # init error log values
  $self->{log_errors} = $enable;
  $self->{log_file} = $logfile;
  $self->{error_file} = $errorfile;
  if ($outputtypes =~ /s/) { $self->{std_out} = 1; } else {$self->{std_out} = 0; }
  if ($outputtypes =~ /b/) { $self->{browser_out} = 1; } else {$self->{browser_out} = 0; }
  if ($outputtypes =~ /f/) { $self->{file_out} = 1; } else {$self->{file_out} = 0; }

  my $error;
  
  # does log already exist?
  my $exists = 0;
  if ( (-e $logfile) ) { $exists = 1; }
#print "error log [" . $logfile . "] exists: $exists\n";
  
  # check if old log should be moved to backup
#  if ($exists) {
#    # read the first line of the file (create date)
#    open $self->{loghandle}, "<$logfile" or $error = "couldn't open $logfile: $!";
#    my $fh = $self->{loghandle};
#    my $timestamp = <$fh>;
#    close($fh);
    
    # hack for some case where timestamp is empty:
#    unless (defined($timestamp)) {$timestamp = "20-2-2008 14:44:58"}
    
    # check the age of the file
#print "logfile: $logfile\n";
#print "timestamp: $timestamp\n";
#    chomp $timestamp;
#    $timestamp =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)/;
#    my $epochageinseconds = timelocal($6, $5, $4, $1, $2-1, $3-1900);
#    my $ageinseconds = time - $epochageinseconds;
#print "check if $ageinseconds is greater than " . $self->{maxageinseconds} . "\n";
#    if ($ageinseconds > $self->{maxageinseconds}) {
#      # back up current log
#      copy($logfile, "$logfile.bak");
#      unlink $logfile;
#      $exists = 0;  # need to start a new log file
##    }
#  }
  
  # if using a log file, open/create it and write out the time
  if ($self->{file_out} == 1 && $enable == 1) {
  # get the current time
  my ($sec, $min, $hours, $mday, $month, $year) = localtime;
  # open/create log file and print the date and time
  open $self->{loghandle}, ">>$logfile" or $error = "couldn't open $logfile: $!";
#if ($error) { print "error: $error\n"; }
    if ($error && length($error) > 0) {
      # can't use log file; shut it down to prevent error messages
      $self->{file_out} = 0;
    } else {
      my $fh = $self->{loghandle};
      if ($exists) {
        print $fh "\n\n$mday-".($month+1)."-".($year+1900)." $hours:$min:$sec\n";
      } else {
        # timestamp should be the first line of a new logfile.
        print $fh "$mday-".($month+1)."-".($year+1900)." $hours:$min:$sec\n";
      }
    }
  }
  if ($self->{browser_out} == 1) {
    print "Content-Type: text/html\n\n";
  }
}

sub logMessage {
  my $self = shift;
  if ($self->{log_errors} == 1) {
    my $message = $_[0];
    my $logfile = $self->{log_file};
    if ($self->{file_out} == 1) {
      my $fh = $self->{loghandle};
      print $fh $message;
    }
    if ($self->{browser_out} == 1) {
      $message =~ s/\n/<br>/g;
      print $message;
    }
    if ($self->{std_out} == 1) {
      print $message;
    }
  }
}

sub reportError {
  my $self = shift;
  my $message = $_[0];

  if (!$self->{errorhandle}) {
    # get the current time
    my ($sec, $min, $hours, $mday, $month, $year) = localtime;
    # open/create error log file and print the date and time
    my $error;
    open $self->{errorhandle}, ">>$self->{error_file}" or $error = "couldn't open $self->{error_file}: $!";
    my $fh = $self->{errorhandle};
    print $fh "\n\n$mday-".($month+1)."-".($year+1900)." $hours:$min:$sec\n";
  }
  
  my $fh = $self->{errorhandle};
  print $fh $message;
}



1;  # so that the require or use succeeds

