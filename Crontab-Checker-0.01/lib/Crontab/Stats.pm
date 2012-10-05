package Crontab::Stats;

use 5.008008;
use strict;
use warnings;
use Carp;
use Crontab::Init;
require Exporter;
use Data::Dumper;

our @ISA = qw(Exporter Crontab::Init);
#@ISA = ("Crontab::Init");

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Crontab::Checker ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );
our $VERSION = '0.01';

#Set the directory path
sub setPath
{
    my ($self,$path) = @_;
    $self->{_dir} = $path if defined($path); # Set _dir in object
}

sub getPath
{
    my ($self) = @_;
    return $self->{_dir};  # Return the value of _dir
}

sub setFileList
{
    my $self = shift;
    my @items;
    if (@_) { @items = @_;}                  # For every item passed
    foreach my $item (@items) {              # append it to the end of
        push(@{ $self->{_fileList} },$item); # of the _fileList in object
    }
}

sub getFileList
{
    my $self = shift;
    return @{ $self->{_fileList} }; 
}

sub getAllFiles
{
    my ($self,$path) = @_;
    opendir (my $dh, $path) or croak;      # Open directory
    my @allFiles = readdir($dh);           # Read contents of directory
    closedir $dh;                          # Close directory
    my @fileList = grep(!/^((\.)|(build.xml))/,@allFiles); # Remove hidden files
    @fileList = sort(@fileList);           # Sort alphabetically
    @fileList = map { $path . '/' .$_ } @fileList;
    return \@fileList;
}

sub mapDir 
{
    my ($self,$filesRef) = @_;
    my @allFiles = @$filesRef;
    my $path = $self->getPath();        # Get path from object
    foreach my $fileType (@allFiles) {  # Loop through list of all files
        if (-d $fileType)
        {
            my $files = $self->getAllFiles($fileType); # If directory then look for
            $self->mapDir($files);                     # files in the directory
        } else {                                       # Else a file was found
            $self->setFileList($fileType);             # then add it to the fileList
        }
    }
}

sub recurseDirs
{
    my ($self,$path) = @_;                 # Supply the path to root
    my $files = $self->getAllFiles($path); # Find files recursively
    $self->mapDir($files);                 # through all the directories
}

sub fileLineStats 
{
    my ($self,$file) = @_;
    open my $content, $file or croak "Could not open $file: $!";
    my $bc  = 0; # Count blank lines
    my $ac  = 0; # Count comments 
    my $ic  = 0; # Count inactive cron
    my $cac = 0; # Count active cron
    my $nc  = 1; # Add to cron count
    while ( my $line = <$content> )
    {
        if ( $line =~ m/^\n/x )
        {
           $bc++; 
        }
        if ( $line =~ m/^\s?[#]+/x )
        {
            $ac++;
        }
        if ( $line =~ m/^\s?[#]+([*]{1}|[0-9])/x )
        {
            $ic++;
        }
        if ( $line =~ m/^\s?([*]{1}|[0-9]{1,2})/x )
        {
            $cac++;
        }
    }
    close $content;
    $self->setBlank($bc);
    $self->setComments($ac);
    $self->setInactiveCron($ic);
    $self->setActiveCron($cac);
    $self->setNumberCrons($nc);
}

sub groupLineStats
{
    my ($self,$path) = @_;
    $self->recurseDirs($path);
    my @fileListRef = $self->getFileList();
    foreach my $file (@fileListRef){
        $self->fileLineStats($file);
    }
}

sub validateCronTime
{
    my ($self,$path) = @_;
    $self->recurseDirs($path);
    my @fileListRef = $self->getFileList();
    my $valid = 0;
    my $warning = 0;
    my $error = 0;
    my $undefined = 0;
    my $other = 0;
    my ($json,$message);
    foreach my $file (@fileListRef){
        open my $content, $file or croak "Could not open $file: $!";
        while ( my $line = <$content> )
        {
            if ( $line =~ m/^\s?([*]|[0-9]{1,2})/x )
            {
               if ( $line =~ m/^(([*]|(([0-5][0-9]|[0-9])[,\/-])+([0-5][0-9]|[0-9])|[0-5][0-9]|[0-9])\s){3}
                                (([*]|(([0-5][0-9]|[0-9])[,\/-])+([0-5][0-9]|[0-9])|[0-5][0-9]|[0-9]|
                                 ([JANFEBMRYUPGSOCTDL]){3}|([janfebmryupgsoctdl]){3})\s)
                                (([*]|(([0-5][0-9]|[0-9])[,\/-])+([0-5][0-9]|[0-9])|[0-5][0-9]|[0-9]|
                                 ([MONTUEDHFRIW]){3}|([montuedhfriw]){3})\s)
                             /x)
               {
                   $valid++;
               }  else {
                   if ( $line =~ m/^\s/x ) {
                       $warning++;
                       $message = 'First character is a whitespace.  Consider removing leading whitespace.';
                       $json = "{\"warning\":{\"$file\":\"$message\"}}";
                       $self->setMessage($json);
                   }
                   elsif ( $line =~ m/([*]{1}|[\/,-]|[a-z,A-Z,0-9])+\s\s/x )
                   {
                       $warning++;
                       $message = 'Multiple whitespace between cron times. Consider removing extra whitespace.';
                       $json = "{\"warning\":{\"$file\":\"$message\"}}";
                       $self->setMessage($json);
                   } 
                   elsif ( $line =~ m/([*]{1}|[0-5][0-9]|[0-9])[\/]([0-5][0-9]|[0-9])/x)
                   {
                       $warning++;
                       $message = 'Not all systems allow the / function in cron. Consider refactoring.';
                       $json = "{\"warning\":{\"$file\":\"$message\"}}";
                       $self->setMessage($json);
                   } else {
                       $undefined++;
                       $message = 'Unknown Match. Report bug with this line.';
                       $json = "{\"undefined\":{\"$file\":\"$message\",\"line\":\"$line\"}}";
                       $self->setMessage($json);
                   }
               }
            } 
            elsif ( $line =~ m/^((@)|(\s?[#]+)|(\n)|(MAILTO|BASE|ORACLE_HOME|TNS_ADMIN|LD_LIBRARY_PATH|MONITOR_HOME)[=])/x ) 
            {
                $other++;
            } else {
                $error++;
                $message = 'Cron entry is not valid.';
                $json = "{\"error\":{\"$file\":\"$message\"}}";
                $self->setWarningList($json);
            }
        }
        close $content;
    }
    $self->setValid($valid);
    $self->setWarning($warning);
    $self->setError($error);
    $self->setUndefined($undefined);
}

sub setMessage
{
    my $self = shift;
    my @items;
    if (@_) { @items = @_;}                  # For every item passed
    foreach my $item (@items) {              # append it to the end of
        push(@{ $self->{_messages} },$item); # of the _messages in object
    }
}

sub setBlank
{
    my ($self,$count) = @_;
    $self->{_blank} = ($self->{_blank} + $count) if defined($count);
}

sub setComments
{
    my ($self,$count) = @_;
    $self->{_comment} = ($self->{_comment} + $count) if defined($count);
}

sub setActiveCron
{
    my ($self,$count) = @_;
    $self->{_activeCron} = ($self->{_activeCron} + $count) if defined($count);
}

sub setInactiveCron
{
    my ($self,$count) = @_;
    $self->{_inactiveCron} = ($self->{_inactiveCron} + $count) if defined($count);
}

sub setNumberCrons
{
    my ($self,$count) = @_;
    $self->{_numberCrons} = ($self->{_numberCrons} + $count) if defined($count);
}

sub setValid
{
    my ($self,$count) = @_;
    $self->{_valid} = ($self->{_valid} + $count) if defined($count);
}

sub setWarning
{
    my ($self,$count) = @_;
    $self->{_warning} = ($self->{_warning} + $count) if defined($count);
}

sub setError
{
    my ($self,$count) = @_;
    $self->{_error} = ($self->{_error} + $count) if defined($count);
}

sub setUndefined
{
    my ($self,$count) = @_;
    $self->{_undefined} = ($self->{_undefined} + $count) if defined($count);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Crontab::Checker - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Crontab::Checker;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Crontab::Checker, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. U. Thor, E<lt>bhill@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
