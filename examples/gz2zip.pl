use strict;
use warnings;

use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use Archive::Zip::SimpleZip qw($SimpleZipError);

die "Usage: gz2zip.pl zipfilename gzfile1 gzfile2...\n"
    unless @ARGV >= 2 ;

my $zipFile = shift ;
my $zip = Archive::Zip::SimpleZip->new($zipFile)
            or die "Cannot create zip file '$zipFile': $SimpleZipError";

for my $gzFile (@ARGV)
{
    my $cleanName = $gzFile ;
    $cleanName =~ s/\.gz$//;

    print "Adding $cleanName\n" ;
    my $zipMember = $zip->openMember(Name => $cleanName)
        or die "Cannot openMember file '$cleanName': $SimpleZipError\n" ;

    gunzip $gzFile => $zipMember
        or die "Cannot gunzip file '$gzFile': $GunzipError $SimpleZipError\n" ;
}
