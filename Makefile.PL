#! perl -w

use strict ;
require 5.006 ;

use private::MakeUtil;
use ExtUtils::MakeMaker 5.16 ;

WriteMakefile( 
    NAME         => 'Archive::Zip::SimpleZip',
    VERSION_FROM => 'lib/Archive/Zip/SimpleZip.pm',
    'dist'       => { COMPRESS     => 'gzip', 
                      TARFLAGS     => '-chvf',
                      SUFFIX       => 'gz',
                      DIST_DEFAULT => 'MyTrebleCheck tardist',
                    },

    (
      $ENV{SKIP_FOR_CORE}
        ? ()
	    : (PREREQ_PM   => { 'IO::Compress::Zip' => 2.030,
                          }
	      )
    ),
       
    (
    $] >= 5.005
        ? (ABSTRACT => 'IO Interface to compressed data files/buffers',
            AUTHOR  => 'Paul Marquess <pmqs@cpan.org>')
        : ()
    ),

    INSTALLDIRS => ($] >= 5.009 ? 'perl' : 'site'),
    
    (
    $] >= 5.009 && $] <= 5.011001 && ! $ENV{PERL_CORE}
        ? (INSTALLPRIVLIB    => '$(INSTALLARCHLIB)')
        : ()
    ),

    META_MERGE => {
        no_index => {
            directory => [ 't', 'private' ],
        },
    },    

    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
        ('LICENSE'  => 'perl')         : ()),    

) ;

# end of file Makefile.PL

