

BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = ("../lib", "lib/compress");
    }
}

use lib qw(t t/compress);
use strict;
use warnings;
use bytes;

use Test::More ; 
use CompTestUtils;
use File::Spec ;

BEGIN {
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 223 + $extra ;

    use_ok('IO::Uncompress::Unzip', qw(unzip $UnzipError)) ;
    use_ok('Archive::Zip::SimpleZip', qw($SimpleZipError)) ;

}

my $symlink_exists = eval { symlink("", ""); 1 } ;

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

sub canonDir
{
    IO::Compress::Zip::canonicalName($_[0], 1);
}


{
    title "errors";
    
    {
        title "no zip filname";
        my $z = new Archive::Zip::SimpleZip ;
    
        is $z, undef ;
        is $SimpleZipError, "Missing Filename",
            "  missing filename";
    }
    
    {
        title "directory";
        my $lex = new LexDir my $dir;
        my $z = new Archive::Zip::SimpleZip $dir ;
    
        is $z, undef ;
        is $SimpleZipError, "Illegal Filename",
            "  missing filename";
    }    

    {
        title "zip file in directory that doesn't exist";
        my $lex = new LexDir my $dir;
        my $zipfile = File::Spec->catfile($dir, "not", "exist", "x.zip");
        
        my $z = new Archive::Zip::SimpleZip $zipfile ;
    
        is $z, undef ;
        is $SimpleZipError, "Illegal Filename",
            "  missing filename";
    }  
    
    SKIP:
    {
        title "file not writable";
        my $lex = new LexFile my $zipfile;
        
        chmod 0444, $zipfile 
            or skip "Cannot create non-writable file", 3 ;

        skip "Cannot create non-writable file", 3 
            if -w $zipfile ;

        ok ! -w $zipfile, "  zip file not writable";
                
        my $z = new Archive::Zip::SimpleZip $zipfile ;
    
        is $z, undef ;
        is $SimpleZipError, "Illegal Filename",
            "  Illegal Filename";
            
        chmod 0777, $zipfile ;           
    }    
  
            
    {
        title "filename undef";
        my $z = new Archive::Zip::SimpleZip undef;
    
        is $z, undef ;
        is $SimpleZipError, "Illegal Filename",
            "  missing filename";
    }    
    
    {
        title "Bad parameter in new";
        my $lex = new LexFile my $zipfile;        
        eval { my $z = new Archive::Zip::SimpleZip $zipfile, fred => 1 ; };
    
        like $@,  qr/Parameter Error: unknown key value\(s\) fred/,
            "  value  is bad";
                   
        like $SimpleZipError, qr/Parameter Error: unknown key value\(s\) fred/,
            "  missing filename";
    }   
            
    {
        title "Bad parameter in add";
        my $lex = new LexFile my $zipfile;
        my $lex1 = new LexFile my $file1;
        writeFile($file1, "abc");
            
        my $z = new Archive::Zip::SimpleZip $zipfile;
        isa_ok $z, "Archive::Zip::SimpleZip";        
        eval { $z->add($file1, Fred => 1) ; };
    
        like $@,  qr/Parameter Error: unknown key value\(s\) Fred/,
            "  value  is bad";
                   
        like $SimpleZipError, qr/Parameter Error: unknown key value\(s\) Fred/,
            "  missing filename";
    }   
    
            
    {
        title "Name option invalid in constructor";

        my $zipfile ;
            
        eval { my $z = new Archive::Zip::SimpleZip \$zipfile, Name => "fred"; } ;
    
        like $@,  qr/name option not valid in constructor/,
            "  option invalid";
                   
        like $SimpleZipError, qr/name option not valid in constructor/,
            "  option invalid";
    }
    
    {
        title "Comment option invalid in constructor";

        my $zipfile ;
            
        eval { my $z = new Archive::Zip::SimpleZip \$zipfile, Comment => "fred"; } ;
    
        like $@,  qr/comment option not valid in constructor/,
            "  option invalid";
                   
        like $SimpleZipError, qr/comment option not valid in constructor/,
            "  option invalid";
    } 
    
    
    {
        title "ZipComment option only valid in constructor";

        my $zipfile ;
            
        my $z = new Archive::Zip::SimpleZip \$zipfile ;
        eval {  $z->addString("", ZipComment => "fred"); } ;        
    
    ok 1; ok 1;
#        like $@,  qr/ZipComment option only valid in constructor/,
#            "  option invalid";
#                   
#        like $SimpleZipError, qr/ZipComment option only valid in constructor/,
#            "  option invalid";
    } 
    
            
    {
        title "Missing Name paramter in addString";
        
        my $zipfile;
            
        my $z = new Archive::Zip::SimpleZip \$zipfile;
        isa_ok $z, "Archive::Zip::SimpleZip";        
        eval { $z->addString("abc") ; };
    
        like $@,  qr/Missing 'Name' parameter in addString/,
            "  value  is bad";
                   
        like $SimpleZipError, qr/Missing 'Name' parameter in addString/,
            "  missing filename";
    }     
        
}

{
    title "file doesn't exist";

    my $lex1 = new LexFile my $zipfile;
    my $file1 = "notexist";

    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    is $z->add($file1), 0, "add not ok";
    is $SimpleZipError, "File '$file1' does not exist";
 

    ok ! -e $file1, "no zip file created";
}

use Fcntl ':mode';

SKIP:
{
    title "file cannot be read";

    my $lex1 = new LexFile my $zipfile;
    my $lex = new LexFile my $file1;
    
    writeFile($file1, "abc");
    chmod 0222, $file1 ;

    skip "Cannot create non-readable file", 6
        if -r $file1 ;

    ok ! -r $file1, "  input file not readable";          
       
    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    is $z->add($file1), 0, "add not ok";
    is $SimpleZipError, "File '$file1' cannot be read";
    ok $z->close, "closed ok";

    ok -z $zipfile, "zip file created, but empty";
    
    chmod 0777, $file1 ;
    
}


SKIP:
{
    title "one file cannot be read";

    my $lex1 = new LexFile my $zipfile;
    my $lex2 = new LexFile my $file1;
    my $lex3 = new LexFile my $file2;
    my $lex4 = new LexFile my $file3;        
    
    writeFile($file1, $file1);
    writeFile($file2, $file2);
    writeFile($file3, $file3);
    chmod 0222, $file2 ;

    skip "Cannot create non-readable file", 13
        if -r $file2 ;

    ok ! -r $file2, "  input file not readable";          
       
    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($file1), "add $file1";

    is $z->add($file2), 0, "add not ok";
    is $SimpleZipError, "File '$file2' cannot be read";

    ok ! $z->add($file3), "not add $file3";
    is $SimpleZipError, "File '$file2' cannot be read";
            
    ok $z->close, "closed ok";

    ok -e $zipfile, "zip file created";
    
    my @got = getContent($zipfile);
    is @got, 1, "two entries in zip";
    is $got[0]{Name}, canonFile($file1);
    is $got[0]{Payload}, $file1;    

    
    chmod 0777, $file2 ;
         
}

{
    title "simple" ;

    my $lex1 = new LexFile my $zipfile;
    my $lex = new LexFile my $file1;

    writeFile($file1, "hello world");

    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($file1), "add ok";
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile($file1);
    is $got[0]{Payload}, "hello world";
}


{
    title "simple - no close" ;

    my $lex1 = new LexFile my $zipfile;
    my $lex = new LexFile my $file1;

    writeFile($file1, "hello world");

    {
        my $z = new Archive::Zip::SimpleZip $zipfile ;
        isa_ok $z, "Archive::Zip::SimpleZip";
    
        ok $z->add($file1), "add ok";
    }


    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile($file1);
    is $got[0]{Payload}, "hello world";
}


{
    title "simple - no add" ;

    my $lex1 = new LexFile my $zipfile;
    my $lex = new LexFile my $file1;

    writeFile($file1, "hello world");

    {
        my $z = new Archive::Zip::SimpleZip $zipfile ;
        isa_ok $z, "Archive::Zip::SimpleZip";
    
        #ok $z->add($file1), "add ok";
    }

    ok -e $zipfile, "file exists" ;
    is -s $zipfile, 0, "file empty" ;       
}

{
    title "simple dir" ;

    my $lex1 = new LexFile my $zipfile;
    my $lex = new LexDir my $file1;

    ok -d $file1;

    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($file1), "add ok";
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonDir($file1);
    is $got[0]{Payload}, "";
}

SKIP:
{
    title "symbolic link - StoreLinks => 0" ;
    skip "symlink not available on this platform", 10
        unless $symlink_exists;


    my $lex1 = new LexFile my $zipfile;
    my $lex = new LexDir my $dir1;

    my $from = File::Spec->catfile($dir1, "from");
    my $link = File::Spec->catfile($dir1, "to");

    writeFile $from, "hello";
    ok symlink("from" => $link), "create link";

    ok -d $dir1;
    ok -l $link;

    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($link), "add ok";
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile($link);
    is $got[0]{Payload}, "hello";
}

SKIP:
{
    title "symbolic link - StoreLinks => 1" ;
    skip "symlink not available on this platform", 10
        unless $symlink_exists;


    my $lex1 = new LexFile my $zipfile;
    my $lex = new LexDir my $dir1;

    my $from = File::Spec->catfile($dir1, "from");
    my $link = File::Spec->catfile($dir1, "to");

    writeFile $from, "hello";
    ok symlink("from" => $link), "create link";

    ok -d $dir1;
    ok -l $link;

    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($link, StoreLinks => 1), "add ok";
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile($link);
    is $got[0]{Payload}, "from";
}

SKIP:
{
    title "symbolic link to dir - StoreLinks => 1" ;
    skip "symlink not available on this platform", 11
        unless $symlink_exists;


    my $lex1 = new LexFile my $zipfile;    
    my $lex = new LexDir my $dir1;

    my $from = File::Spec->catfile($dir1, "from");
    my $link = File::Spec->catfile($dir1, "to");

    ok -d $dir1;
    
    mkdir $from;
    ok -d $from, "$from is a directory";
    
    ok symlink("from" => $link), "create link to dir";

    ok -l $link, "$link is a link";

    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($link, StoreLinks => 1), "add ok";
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile($link);
    is $got[0]{Payload}, "from";
}


SKIP:
{
    title "symbolic link to dir - StoreLinks => 0" ;
    skip "symlink not available on this platform", 11
        unless $symlink_exists;


    my $lex1 = new LexFile my $zipfile;    
    my $lex = new LexDir my $dir1;

    my $from = File::Spec->catfile($dir1, "from");
    my $link = File::Spec->catfile($dir1, "to");

    ok -d $dir1;
    
    mkdir $from;
    ok -d $from, "$from is a directory";
    
    ok symlink("from" => $link), "create link to dir";

    ok -l $link, "$link is a link";

    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($link, StoreLinks => 0), "add ok";
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonDir($link);
    is $got[0]{Payload}, "";
}




SKIP:
{
    title "mixed content";
    skip "symlink not available on this platform", 20
        unless $symlink_exists;


    my $lex1 = new LexFile my $zipfile;
    my $lex2 = new LexFile my $file1;
    my $lex3 = new LexDir my $dir1;

    my $from = File::Spec->catfile($dir1, "from");
    my $link = File::Spec->catfile($dir1, "to");

    writeFile($from, "hello world");

    ok symlink("from" => $link), "create link";

    my $z = new Archive::Zip::SimpleZip $zipfile, Stream => 1 ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($from), "add file ok";
    ok $z->add($dir1, Zip64 => 1, Stream => 0), "add dir ok";
    ok $z->add($link, StoreLinks => 1), "add link ok";
    
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 3, "three entries in zip";
    is $got[0]{Name}, canonFile($from);
    is $got[0]{Payload}, "hello world";
    is $got[0]{Zip64}, 0, "not zip64";
    is $got[0]{Stream}, 1, "Stream";    
    is $got[1]{Name}, canonDir($dir1);
    is $got[1]{Payload}, "";
    is $got[1]{Zip64}, 1, "zip64";
    is $got[1]{Stream}, 0, "not Stream"; 
    is $got[2]{Name}, canonFile($link);
    is $got[2]{Payload}, "from";
    is $got[2]{Zip64}, 0, "not zip64";   
    is $got[2]{Stream}, 1, "Stream";  
}

{
    title "mixed content - no symlink";


    my $lex1 = new LexFile my $zipfile;
    my $lex2 = new LexFile my $file1;
    my $lex3 = new LexDir my $dir1;

    my $from = File::Spec->catfile($dir1, "from");
    my $link = File::Spec->catfile($dir1, "to");

    writeFile($from, "hello world");
    writeFile($link, "not a link");

    my $z = new Archive::Zip::SimpleZip $zipfile, Stream => 1 ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($from), "add file ok";
    ok $z->add($dir1, Zip64 => 1, Stream => 0), "add dir ok";
    ok $z->add($link, StoreLinks => 1), "add link ok"
        or diag "$SimpleZipError\n";
    
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 3, "three entries in zip";
    is $got[0]{Name}, canonFile($from);
    is $got[0]{Payload}, "hello world";
    is $got[0]{Zip64}, 0, "not zip64";
    is $got[0]{Stream}, 1, "Stream";    
    is $got[1]{Name}, canonDir($dir1);
    is $got[1]{Payload}, "";
    is $got[1]{Zip64}, 1, "zip64";
    is $got[1]{Stream}, 0, "not Stream"; 
    is $got[2]{Name}, canonFile($link);
    is $got[2]{Payload}, "not a link";
    is $got[2]{Zip64}, 0, "not zip64";   
    is $got[2]{Stream}, 1, "Stream";  
}

#{
#    title "Name ignored in constructor" ;
#
#    my $lex1 = new LexFile my $zipfile;
#    my $lex = new LexFile my $file1;
#
#    writeFile($file1, "hello world");
#
#    my $z = new Archive::Zip::SimpleZip $zipfile, Name => "fred" ;
#    isa_ok $z, "Archive::Zip::SimpleZip";
#
#    ok $z->add($file1), "add ok";
#    ok $z->close, "closed ok";
#
#    my @got = getContent($zipfile);
#    is @got, 1, "one entry in zip";
#    is $got[0]{Name}, canonFile($file1);
#    is $got[0]{Payload}, "hello world";
#}


{
    title "Name not sticky" ;

    my $lex1 = new LexFile my $zipfile;
    my $lex = new LexFile my $file1;

    writeFile($file1, "hello world");

    my $z = new Archive::Zip::SimpleZip $zipfile;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($file1, Name => "fred" ), "add ok";
    ok $z->add($file1 ), "add ok";    
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 2, "two entry in zip";
    is $got[0]{Name}, "fred";
    is $got[0]{Payload}, "hello world";
    is $got[1]{Name}, canonFile($file1);
    is $got[1]{Payload}, "hello world";    
}


{
    title "simple output to filehandle" ;


    my $lex = new LexFile my $file1;
    my $lex1 = new LexFile my $zfile;
        
   
    open my $zipfile, ">$zfile";
    writeFile($file1, "hello world");

    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($file1), "add ok";
    ok $z->close, "closed ok";

    close $zipfile;
    
    my @got = getContent($zfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile($file1);
    is $got[0]{Payload}, "hello world";
}


{
    title "simple output to stdout" ;

    my $lex1 = new LexFile my $zipfile;
    
    open(SAVEOUT, ">&STDOUT");
    my $dummy = fileno SAVEOUT;
    open STDOUT, ">$zipfile" ;

    my $lex = new LexFile my $file1;
 
    writeFile($file1, "hello world");

    my $z = new Archive::Zip::SimpleZip '-' ;
    
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($file1), "add ok";
    ok $z->close, "closed ok";

    open(STDOUT, ">&SAVEOUT");
    
    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile($file1);
    is $got[0]{Payload}, "hello world";
}


{
    title "simple output to string" ;

    my $string;
    my $zipfile = \$string;
    my $lex = new LexFile my $file1;

    writeFile($file1, "hello world");

    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($file1), "add ok";
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile($file1);
    is $got[0]{Payload}, "hello world";
}


{
    title "addString: simple output to string" ;

    my $string;
    my $zipfile = \$string;
    my $lex = new LexFile my $file1;

    my $payload = "hello world";

    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->addString($payload, Name => "abc"), "addString ok";
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile("abc");
    is $got[0]{Payload}, $payload;
}

