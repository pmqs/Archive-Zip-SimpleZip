use lib qw(t t/compress);

use strict;
use warnings;

use Test::More ;
use CompTestUtils;

BEGIN
{
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 24 + $extra ;

    use_ok('Archive::Zip::SimpleZip', qw($SimpleZipError)) ;
    use_ok('IO::Compress::Gzip', qw(gzip $GzipError)) ;
    use_ok('IO::Uncompress::Gunzip', qw(gunzip $GunzipError)) ;
    use_ok('IO::Uncompress::Unzip', qw(unzip $UnzipError)) ;
}


my $Inc = join " ", map qq["-I$_"] => @INC;
$Inc = '"-MExtUtils::testlib"'
    if eval " require ExtUtils::testlib; " ;

my $Perl = ($ENV{'FULLPERL'} or $^X or 'perl') ;
$Perl = qq["$Perl"] if $^O eq 'MSWin32' ;

$Perl = "$Perl $Inc -w" ;
#$Perl .= " -Mblib " ;
my $examples = "./examples/";

sub runScript
{
    my $command = shift ;
    my $expected = shift ;

    my $lex = new LexFile my $stderr ;

    my $cmd = "$command 2>$stderr";
    my $stdout = `$cmd` ;

    my $aok = 1 ;

    $aok &= is $?, 0, "  exit status is 0" ;

    $aok &= is readFile($stderr), '', "  no stderr" ;

    $aok &= is $stdout, $expected, "  expected content is ok"
        if defined $expected ;

    if (! $aok) {
        diag "Command line: $cmd";
        my ($file, $line) = (caller)[1,2];
        diag "Test called from $file, line $line";
    }

    1 while unlink $stderr;
}

sub getContent
{
    my $filename = shift;

    my $u = new IO::Uncompress::Unzip $filename, Append => 1, @_
        or die "Cannot open $filename: $UnzipError";

    isa_ok $u, "IO::Uncompress::Unzip";

    my @content;
    my $status ;

    for ($status = 1; $status > 0 ; $status = $u->nextStream())
    {
        die "xxx" if ! defined $u;
        my %info = %{ $u->getHeaderInfo() } ;
        my $name = $u->getHeaderInfo()->{Name};
        #warn "Processing member $name\n" ;

        my $buff = '';
        1 while ($status = $u->read($buff)) ;
        $info{Payload} = $buff;

        #push @content, [$name, $buff];
        push @content, \%info;
        last unless $status == 0;
    }

    die "Error processing $filename: $status $!\n"
        if $status < 0 ;

    return @content;
}

sub canonFile
{
    IO::Compress::Zip::canonicalName($_[0], 0);
}


{
    # gz2zip
    ###########
    title "gz2zip" ;

    my $lex = new LexFile my $gz1, my $gz2, my $gz3, my $zipfile;

    ok gzip(\"gzip 1" => $gz1), "  gzip 1 ok";
    ok gzip(\"gzip 2" => $gz2), "  gzip 2 ok";
    ok gzip(\"gzip 3" => $gz3), "  gzip 3 ok";

    my $data ;
    ok gunzip($gz1 => \$data), "  gunzip 1 ok" ;
    is $data, "gzip 1",        "  1 data ok" ;
    ok gunzip($gz2 => \$data), "  gunzip 2 ok" ;
    is $data, "gzip 2",        "  2 data ok" ;
    ok gunzip($gz3 => \$data), "  gunzip 3 ok" ;
    is $data, "gzip 3",        "  3 data ok" ;

    runScript "$Perl ${examples}/gz2zip.pl $zipfile $gz1 $gz2 $gz3" ;

    my @got = getContent($zipfile);
    is @got, 3, "  three entries in $zipfile";
    is $got[0]{Name}, canonFile($gz1), "  member1 Name ok";
    is $got[0]{Payload}, "gzip 1",     "  member1 Payload ok";
    is $got[1]{Name}, canonFile($gz2), "  member1 Name ok";
    is $got[1]{Payload}, "gzip 2",     "  member2 Payload ok";
    is $got[2]{Name}, canonFile($gz3), "  member3 Name ok";
    is $got[2]{Payload}, "gzip 3",     "  member3 Payload ok";

}
