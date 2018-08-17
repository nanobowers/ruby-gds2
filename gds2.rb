class GDS2

  #require 5.010001
  VERSION = '3.35'
  ## Note: '@ ( # )' used by the what command  E.g. what GDS2.pm
  REVISION = '@(#) $Id: GDS2.pm,v $ $Revision: 3.35 $ $Date: 2017-10-04 03:27:57-06 $'
  #

  # 
  # = NAME
  # 
  # GDS2 - GDS2 stream module
  # 
  # = SYNOPSIS
  # 
  # This is GDS2, a module for creating programs to read and/or write GDS2 files.
  # 
  # Send feedback/suggestions to
  # perl -le '$_=q(Zpbhgnpe@pvnt.uxa);$_=~tr/n-sa-gt-zh-mZ/a-zS/;print;'
  # 
  # = COPYRIGHT
  # 
  # Author: Ken Schumack (c) 1999-2017. All rights reserved.
  # This module is free software. It may be used, redistributed
  # and/or modified under the terms of the Perl Artistic License.
  # ( see http://www.perl.com/pub/a/language/misc/Artistic.html )
  #  Have fun, Ken
  # 
  # Schumack@cpan.org
  # 
  # = DESCRIPTION
  # 
  # GDS2 allows you to read and write GDS2 files record by record in a
  # stream fashion which inherently uses little memory. It is capable but
  # not fast. If you have large files you may be happier using the C/C++
  # http://sourceforge.net/projects/gds2/ which can easily be used by Perl.
  # 

  #
  # Contributor Modification: Toby Schaffer 2004-01-21
  # returnUnitsAsArray() added which returns user units and database
  # units as a 2 element array.
  #
  # Contributor Modification: Peter Baumbach 2002-01-11
  # returnRecordAsPerl() was created to facilitate the creation of
  # parameterized gds2 data with perl. -Years later Andreas Pawlak
  # pointed out a endian problem that needed to be addressed.
  #
  #BEGIN {

  TRUE    = 1
  FALSE   = 0
  UNKNOWN = -1

  HAVE_FLOCK = TRUE;  ## some systems still may not have this...manually change
  #    use Config
  #    use IO::File
  #end

  #if  HAVE_FLOCK 
  #    use Fcntl %q(:flock);  # import LOCK_* constants
  #end

  #no strict %w( refs )

  #isLittleEndian = FALSE; #default - was developed on a BigEndian machine
  #isLittleEndian = TRUE if config['byteorder'] =~ /^1/ ; ## Linux mswin32 cygwin vms
  # Unclear if we need bigendian support or how to do this properly with Ruby
  @isLittleEndian = TRUE
  
  ################################################################################
  ## GDS2 STREAM RECORD DATATYPES
  NO_REC_DATA  = 0
  BIT_ARRAY    = 1
  INTEGER_2    = 2
  INTEGER_4    = 3
  REAL_4       = 4; ## NOT supported, should not be found in any GDS2
  REAL_8       = 5
  ASCII_STRING = 6
  ################################################################################

  ################################################################################
  ## GDS2 STREAM RECORD TYPES
  HEADER       =  0;   ## 2-byte Signed Integer
  BGNLIB       =  1;   ## 2-byte Signed Integer
  LIBNAME      =  2;   ## ASCII String
  UNITS        =  3;   ## 8-byte Real
  ENDLIB       =  4;   ## no data present
  BGNSTR       =  5;   ## 2-byte Signed Integer
  STRNAME      =  6;   ## ASCII String
  ENDSTR       =  7;   ## no data present
  BOUNDARY     =  8;   ## no data present
  PATH         =  9;   ## no data present
  SREF         = 10;   ## no data present
  AREF         = 11;   ## no data present
  TEXT         = 12;   ## no data present
  LAYER        = 13;   ## 2-byte Signed Integer
  DATATYPE     = 14;   ## 2-byte Signed Integer
  WIDTH        = 15;   ## 4-byte Signed Integer
  XY           = 16;   ## 2-byte Signed Integer
  ENDEL        = 17;   ## no data present
  SNAME        = 18;   ## ASCII String
  COLROW       = 19;   ## 2 2-byte Signed Integer
  TEXTNODE     = 20;   ## no data present
  NODE         = 21;   ## no data present
  TEXTTYPE     = 22;   ## 2-byte Signed Integer
  PRESENTATION = 23;   ## Bit Array
  SPACING      = 24;   ## discontinued
  STRING       = 25;   ## ASCII String
  STRANS       = 26;   ## Bit Array
  MAG          = 27;   ## 8-byte Real
  ANGLE        = 28;   ## 8-byte Real
  UINTEGER     = 29;   ## UNKNOWN User int, used only in Calma V2.0
  USTRING      = 30;   ## UNKNOWN User string, used only in Calma V2.0
  REFLIBS      = 31;   ## ASCII String
  FONTS        = 32;   ## ASCII String
  PATHTYPE     = 33;   ## 2-byte Signed Integer
  GENERATIONS  = 34;   ## 2-byte Signed Integer
  ATTRTABLE    = 35;   ## ASCII String
  STYPTABLE    = 36;   ## ASCII String "Unreleased feature"
  STRTYPE      = 37;   ## 2-byte Signed Integer "Unreleased feature"
  EFLAGS       = 38;   ## BIT_ARRAY  Flags for template and exterior data.  bits 15 to 0, l to r 0=template,
  ##   1=external data, others unused
  ELKEY        = 39;   ## INTEGER_4  "Unreleased feature"
  LINKTYPE     = 40;   ## UNKNOWN    "Unreleased feature"
  LINKKEYS     = 41;   ## UNKNOWN    "Unreleased feature"
  NODETYPE     = 42;   ## INTEGER_2  Nodetype specification. On Calma this could be 0 to 63, GDSII allows 0 to 255.
  ##   Of course a 2 byte integer allows up to 65535...
  PROPATTR     = 43;   ## INTEGER_2  Property number.
  PROPVALUE    = 44;   ## STRING     Property value. On GDSII, 128 characters max, unless an SREF, AREF, or NODE,
  ##   which may have 512 characters.
  BOX          = 45;   ## NO_DATA    The beginning of a BOX element.
  BOXTYPE      = 46;   ## INTEGER_2  Boxtype specification.
  PLEX         = 47;   ## INTEGER_4  Plex number and plexhead flag. The least significant bit of the most significant
  ##    byte is the plexhead flag.
  BGNEXTN      = 48;   ## INTEGER_4  Path extension beginning for pathtype 4 in Calma CustomPlus. In database units,
  ##    may be negative.
  ENDEXTN      = 49;   ## INTEGER_4  Path extension end for pathtype 4 in Calma CustomPlus. In database units, may be negative.
  TAPENUM      = 50;   ## INTEGER_2  Tape number for multi-reel stream file.
  TAPECODE     = 51;   ## INTEGER_2  Tape code to verify that the reel is from the proper set. 12 bytes that are
  ##   supposed to form a unique tape code.
  STRCLASS     = 52;   ## BIT_ARRAY  Calma use only.
  RESERVED     = 53;   ## INTEGER_4  Used to be NUMTYPES per Calma GDSII Stream Format Manual, v6.0.
  FORMAT       = 54;   ## INTEGER_2  Archive or Filtered flag.  0: Archive 1: filtered
  MASK         = 55;   ## STRING     Only in filtered streams. Layers and datatypes used for mask in a filtered
  ##   stream file. A string giving ranges of layers and datatypes separated by a semicolon.
  ##   There may be more than one mask in a stream file.
  ENDMASKS     = 56;   ## NO_DATA    The end of mask descriptions.
  LIBDIRSIZE   = 57;   ## INTEGER_2  Number of pages in library director, a GDSII thing, it seems to have only been
  ##   used when Calma INFORM was creating a new library.
  SRFNAME      = 58;   ## STRING     Calma "Sticks"(c) rule file name.
  LIBSECUR     = 59;   ## INTEGER_2  Access control list stuff for CalmaDOS, ancient. INFORM used this when creating
  ##   a new library. Had 1 to 32 entries with group numbers, user numbers and access rights.
  #################################################################################################
  #use vars '$StrSpace'
  #use vars '$ElmSpace'
  @strspace=''
  @elmspace=''

  recordtypenumbers = {
    'HEADER'      => HEADER,
    'BGNLIB'      => BGNLIB,
    'LIBNAME'     => LIBNAME,
    'UNITS'       => UNITS,
    'ENDLIB'      => ENDLIB,
    'BGNSTR'      => BGNSTR,
    'STRNAME'     => STRNAME,
    'ENDSTR'      => ENDSTR,
    'BOUNDARY'    => BOUNDARY,
    'PATH'        => PATH,
    'SREF'        => SREF,
    'AREF'        => AREF,
    'TEXT'        => TEXT,
    'LAYER'       => LAYER,
    'DATATYPE'    => DATATYPE,
    'WIDTH'       => WIDTH,
    'XY'          => XY,
    'ENDEL'       => ENDEL,
    'SNAME'       => SNAME,
    'COLROW'      => COLROW,
    'TEXTNODE'    => TEXTNODE,
    'NODE'        => NODE,
    'TEXTTYPE'    => TEXTTYPE,
    'PRESENTATION'=> PRESENTATION,
    'SPACING'     => SPACING,
    'STRING'      => STRING,
    'STRANS'      => STRANS,
    'MAG'         => MAG,
    'ANGLE'       => ANGLE,
    'UINTEGER'    => UINTEGER,
    'USTRING'     => USTRING,
    'REFLIBS'     => REFLIBS,
    'FONTS'       => FONTS,
    'PATHTYPE'    => PATHTYPE,
    'GENERATIONS' => GENERATIONS,
    'ATTRTABLE'   => ATTRTABLE,
    'STYPTABLE'   => STYPTABLE,
    'STRTYPE'     => STRTYPE,
    'EFLAGS'      => EFLAGS,
    'ELKEY'       => ELKEY,
    'LINKTYPE'    => LINKTYPE,
    'LINKKEYS'    => LINKKEYS,
    'NODETYPE'    => NODETYPE,
    'PROPATTR'    => PROPATTR,
    'PROPVALUE'   => PROPVALUE,
    'BOX'         => BOX,
    'BOXTYPE'     => BOXTYPE,
    'PLEX'        => PLEX,
    'BGNEXTN'     => BGNEXTN,
    'ENDEXTN'     => ENDEXTN,
    'TAPENUM'     => TAPENUM,
    'TAPECODE'    => TAPECODE,
    'STRCLASS'    => STRCLASS,
    'RESERVED'    => RESERVED,
    'FORMAT'      => FORMAT,
    'MASK'        => MASK,
    'ENDMASKS'    => ENDMASKS,
    'LIBDIRSIZE'  => LIBDIRSIZE,
    'SRFNAME'     => SRFNAME,
    'LIBSECUR'    => LIBSECUR,
  }

  recordtypestrings = [ ## for ascii print of GDS
    'HEADER',
    'BGNLIB',
    'LIBNAME',
    'UNITS',
    'ENDLIB',
    'BGNSTR',
    'STRNAME',
    'ENDSTR',
    'BOUNDARY',
    'PATH',
    'SREF',
    'AREF',
    'TEXT',
    'LAYER',
    'DATATYPE',
    'WIDTH',
    'XY',
    'ENDEL',
    'SNAME',
    'COLROW',
    'TEXTNODE',
    'NODE',
    'TEXTTYPE',
    'PRESENTATION',
    'SPACING',
    'STRING',
    'STRANS',
    'MAG',
    'ANGLE',
    'UINTEGER',
    'USTRING',
    'REFLIBS',
    'FONTS',
    'PATHTYPE',
    'GENERATIONS',
    'ATTRTABLE',
    'STYPTABLE',
    'STRTYPE',
    'EFLAGS',
    'ELKEY',
    'LINKTYPE',
    'LINKKEYS',
    'NODETYPE',
    'PROPATTR',
    'PROPVALUE',
    'BOX',
    'BOXTYPE',
    'PLEX',
    'BGNEXTN',
    'ENDEXTN',
    'TAPENUM',
    'TAPECODE',
    'STRCLASS',
    'RESERVED',
    'FORMAT',
    'MASK',
    'ENDMASKS',
    'LIBDIRSIZE',
    'SRFNAME',
    'LIBSECUR',
  ]
  compactrecordtypestrings = [ ## for compact ascii print of GDS (GDT format) see http://sourceforge.net/projects/gds2/
    'gds2{',          #HEADER
    '',               #BGNLIB
    'lib',            #LIBNAME
    '',               #UNITS
    '}',              #ENDLIB
    'cell{',          #BGNSTR
    '',               #STRNAME
    '}',              #ENDSTR
    'b{',             #BOUNDARY
    'p{',             #PATH
    's{',             #SREF
    'a{',             #AREF
    't{',             #TEXT
    '',               #LAYER
    ' dt',            #DATATYPE
    ' w',             #WIDTH
    ' xy(',           #XY  #)
    '}',              #ENDEL
    '',               #SNAME
    ' cr',            #COLROW
    ' tn',            #TEXTNODE
    ' no',            #NODE
    ' tt',            #TEXTTYPE
    '',               #PRESENTATION'
    ' sp',            #SPACING
    '',               #STRING
    '',               #STRANS
    ' m',             #MAG
    ' a',             #ANGLE
    ' ui',            #UINTEGER
    ' us',            #USTRING
    ' rl',            #REFLIBS
    ' f',             #FONTS
    ' pt',            #PATHTYPE
    ' gen',           #GENERATIONS
    ' at',            #ATTRTABLE
    ' st',            #STYPTABLE
    ' strt',          #STRTYPE
    ' ef',            #EFLAGS
    ' ek',            #ELKEY
    ' lt',            #LINKTYPE
    ' lk',            #LINKKEYS
    ' nt',            #NODETYPE
    ' ptr',           #PROPATTR
    ' pv',            #PROPVALUE
    ' bx',            #BOX
    ' bt',            #BOXTYPE
    ' px',            #PLEX
    ' bx',            #BGNEXTN
    ' ex',            #ENDEXTN
    ' tnum',          #TAPENUM
    ' tcode',         #TAPECODE
    ' strc',          #STRCLASS
    ' resv',          #RESERVED
    ' fmt',           #FORMAT
    ' msk',           #MASK
    ' emsk',          #ENDMASKS
    ' lds',           #LIBDIRSIZE
    ' srfn',          #SRFNAME
    ' libs',          #LIBSECUR
  ]

  ###################################################
  recordtypedata = {
    'HEADER'       => INTEGER_2,
    'BGNLIB'       => INTEGER_2,
    'LIBNAME'      => ASCII_STRING,
    'UNITS'        => REAL_8,
    'ENDLIB'       => NO_REC_DATA,
    'BGNSTR'       => INTEGER_2,
    'STRNAME'      => ASCII_STRING,
    'ENDSTR'       => NO_REC_DATA,
    'BOUNDARY'     => NO_REC_DATA,
    'PATH'         => NO_REC_DATA,
    'SREF'         => NO_REC_DATA,
    'AREF'         => NO_REC_DATA,
    'TEXT'         => NO_REC_DATA,
    'LAYER'        => INTEGER_2,
    'DATATYPE'     => INTEGER_2,
    'WIDTH'        => INTEGER_4,
    'XY'           => INTEGER_4,
    'ENDEL'        => NO_REC_DATA,
    'SNAME'        => ASCII_STRING,
    'COLROW'       => INTEGER_2,
    'TEXTNODE'     => NO_REC_DATA,
    'NODE'         => NO_REC_DATA,
    'TEXTTYPE'     => INTEGER_2,
    'PRESENTATION' => BIT_ARRAY,
    'SPACING'      => UNKNOWN, #INTEGER_4, discontinued
    'STRING'       => ASCII_STRING,
    'STRANS'       => BIT_ARRAY,
    'MAG'          => REAL_8,
    'ANGLE'        => REAL_8,
    'UINTEGER'     => UNKNOWN, #INTEGER_4, no longer used
    'USTRING'      => UNKNOWN, #ASCII_STRING, no longer used
    'REFLIBS'      => ASCII_STRING,
    'FONTS'        => ASCII_STRING,
    'PATHTYPE'     => INTEGER_2,
    'GENERATIONS'  => INTEGER_2,
    'ATTRTABLE'    => ASCII_STRING,
    'STYPTABLE'    => ASCII_STRING, # unreleased feature
    'STRTYPE'      => INTEGER_2, #INTEGER_2, unreleased feature
    'EFLAGS'       => BIT_ARRAY,
    'ELKEY'        => INTEGER_4, #INTEGER_4, unreleased feature
    'LINKTYPE'     => INTEGER_2, #unreleased feature
    'LINKKEYS'     => INTEGER_4, #unreleased feature
    'NODETYPE'     => INTEGER_2,
    'PROPATTR'     => INTEGER_2,
    'PROPVALUE'    => ASCII_STRING,
    'BOX'          => NO_REC_DATA,
    'BOXTYPE'      => INTEGER_2,
    'PLEX'         => INTEGER_4,
    'BGNEXTN'      => INTEGER_4,
    'ENDEXTN'      => INTEGER_4,
    'TAPENUM'      => INTEGER_2,
    'TAPECODE'     => INTEGER_2,
    'STRCLASS'     => UNKNOWN,
    'RESERVED'     => INTEGER_4,
    'FORMAT'       => INTEGER_2,
    'MASK'         => ASCII_STRING,
    'ENDMASKS'     => NO_REC_DATA,
    'LIBDIRSIZE'   => UNKNOWN, #INTEGER_2
    'SRFNAME'      => ASCII_STRING,
    'LIBSECUR'     => UNKNOWN, #INTEGER_2,
  }

  # This is the default class for the GDS2 object to use when all else fails.
  #GDS2::defaultclass = 'GDS2' unless defined GDS2::defaultclass

  g_gdtstring = ""
  g_epsilon = "0.001"; ## to take care of floating point representation problems
  g_fltlen = 3
  #it's own name space...
  begin
    fltLenTmp = sprintf("%0.99f",(1.0/3.0)).sub(/^0.(3+).*/, "\\1").length - 10
    if  fltLenTmp > g_epsilon.length  # try to make smaller if we can...
      g_epsilon = sprintf("%0.#{fltLenTmp}f1",0)
      g_fltlen = fltLenTmp
    end
  end
  g_epsilon = g_epsilon.to_f # ensure it's a number

  ################################################################################

  # = Examples
  # 
  #   Layer change:
  #     here's a bare bones script to change all layer 59 to 66 given a file to
  #     read and a new file to create.
  #     #!/usr/bin/perl -w
  #     use strict;
  #     use GDS2;
  #     my $fileName1 = $ARGV[0];
  #     my $fileName2 = $ARGV[1];
  #     my $gds2File1 = new GDS2(-fileName => $fileName1);
  #     my $gds2File2 = new GDS2(-fileName => ">$fileName2");
  #     while (my $record = $gds2File1 -> readGds2Record)
  #     {
  #         if ($gds2File1 -> returnLayer == 59)
  #         {
  #             $gds2File2 -> printLayer(-num=>66);
  #         }
  #         else
  #         {
  #             $gds2File2 -> printRecord(-data=>$record);
  #         }
  #     }
  # 
  # 
  #   Gds2 dump:
  #     here's a complete program to dump the contents of a stream file.
  #     #!/usr/bin/perl -w
  #     use GDS2;
  #     $\="\n";
  #     my $gds2File = new GDS2(-fileName=>$ARGV[0]);
  #     while ($gds2File -> readGds2Record)
  #     {
  #         print $gds2File -> returnRecordAsString;
  #     }
  # 
  # 
  #   Gds2 dump in GDT format: which is smaller and easier to parse - http://sourceforge.net/projects/gds2/
  #     #!/usr/bin/perl -w
  #     use GDS2;
  #     my $gds2File = new GDS2(-fileName=>$ARGV[0]);
  #     while ($gds2File -> readGds2Record)
  #     {
  #         print $gds2File -> returnRecordAsString(-compact=>1);
  #     }
  # 
  #   Dump from the command line of a bzip2 compressed file:
  #   perl -MGDS2 -MFileHandle -MIPC::Open3 -e '$f1=new FileHandle;$f0=new FileHandle;open3($f0,$f1,$f1,"bzcat test.gds.bz2");$gds=new GDS2(-fileHandle=>$f1);while($gds->readGds2Record){print $gds->returnRecordAsString(-compact=>1)}'
  # 
  #   Create a complete GDS2 stream file from scratch:
  #     #!/usr/bin/perl -w
  #     use GDS2;
  #     my $gds2File = new GDS2(-fileName=>'>test.gds');
  #     $gds2File -> printInitLib(-name=>'testlib');
  #     $gds2File -> printBgnstr(-name=>'test');
  #     $gds2File -> printPath(
  #                     -layer=>6,
  #                     -pathType=>0,
  #                     -width=>2.4,
  #                     -xy=>[0,0, 10.5,0, 10.5,3.3],
  #                  );
  #     $gds2File -> printSref(
  #                     -name=>'contact',
  #                     -xy=>[4,5.5],
  #                  );
  #     $gds2File -> printAref(
  #                     -name=>'contact',
  #                     -columns=>2,
  #                     -rows=>3,
  #                     -xy=>[0,0, 10,0, 0,15],
  #                  );
  #     $gds2File -> printEndstr;
  #     $gds2File -> printBgnstr(-name => 'contact');
  #     $gds2File -> printBoundary(
  #                     -layer=>10,
  #                     -xy=>[0,0, 1,0, 1,1, 0,1],
  #                  );
  #     $gds2File -> printEndstr;
  #     $gds2File -> printEndlib();
  # 
  # ################################################################################
  # 
  # = METHODS
  # 
  # == new - open gds2 file
  # 
  #   usage:
  #   my $gds2File  = new GDS2(-fileName => "filename.gds2"); ## to read
  #   my $gds2File2 = new GDS2(-fileName => ">filename.gds2"); ## to write
  # 
  #   -or- provide your own fileHandle:
  # 
  #   my $gds2File  = new GDS2(-fileHandle => $fh); ## e.g. to attach to a compression/decompression pipe
  # 

  def new(fileName = nil, fileHandle = nil, resolution = 1000)

    if fileName && fileHandle 
      raise "new expects a gds2 file name -OR- a file handle. Do not give both."
    end
    unless fileName || fileHandle 
      
      raise "new expects a -fileName => 'name' OR and -fileHandle => fh $!"
    end
    lockMode = LOCK_SH;   ## default
    if fileName 
      
      openModStr = substr(fileName,0,2);  ### looking for > or >>
      openModStr.sub!(/^\s+/, '')
      openModStr.gsub!(/[^\+>]+/, '')
      openModeNum = O_RDONLY
      if  openModStr =~ %r|^\+| 
        
        warn("Ignoring '+' in open mode"); ## not handling this yet...
        openModStr.sub!(/\++/, '')
      end
      if  openModStr == '>' 
        
        openModeNum = O_WRONLY|O_CREAT
        lockMode = LOCK_EX
        fileName.sub!(/^$openModStr/, '')
        
      elsif  openModStr == '>>' 
        
        openModeNum = O_WRONLY|O_APPEND
        lockMode = LOCK_EX
        fileName.sub!(/^$openModStr/, '')
      end
      fileHandle = new IO::File
      fileHandle.open("#{fileName}",openModeNum) or raise "Unable to open #{fileName} because $!"
      if  HAVE_FLOCK 
        
        flock(fileHandle,lockMode) or raise "File lock on #{fileName} failed because $!"
      end
    end
    raise "new expects a positive integer resolution. (#{resolution}) $!" if  (resolution <= 0) || (resolution !~ %r|^\d+$|) 
    binmode fileHandle, ':raw'
    @Fd         = fileHandle.fileno
    @FileHandle = fileHandle
    @FileName   = fileName; ## the gds2 filename
    @BytesDone  = 0;         ## total file size so far
    @EOLIB      = FALSE;     ## end of library flag
    @INHEADER   = UNKNOWN;   ## in header? flag TRUE | FALSE | UNKNOWN
    @INDATA     = FALSE;     ## in data? flag TRUE | FALSE
    @Length     = 0;         ## length of data
    @DataType   = UNKNOWN;   ## one of 7 gds datatypes
    @UUnits     = -1.0;      ## for gds2 file  e.g. 0.001
    @DBUnits    = -1.0;      ## for gds2 file  e.g. 1e-9
    @Record     = '';        ## the whole record as found in gds2 file
    @RecordType = UNKNOWN
    @DataIndex  = 0
    @RecordData = ()
    @CurrentDataList = ''
    @InBoundary = FALSE;     ##
    @InTxt      = FALSE;     ##
    @DateFld    = 0;     ##
    @Resolution = resolution
    @UsingPrettyPrint = FALSE; ## print as string ...
    self
  end
  ################################################################################

  #######
  #private method to check how accurately users perl can do math
  def getG_epsilon (*arg)

    
    g_epsilon
  end
  ################################################################################

  #######
  #private method to check how accurately users perl can do math
  def getG_fltLen (*arg)

    
    g_fltlen
  end
  ################################################################################

  #######
  #private method to report Endianness
  def endianness (*arg)
    @isLittleEndian
  end
  ################################################################################

  #######
  #private method to clean up number
  def cleanExpNum

    num = shift
    num = sprintf("%0.#{g_fltlen}e",num)
    num.sub!(/([1-9])0+e/, '$1e')
    num.sub!(/(\d)\.0+e/, '$1e')
    num
  end
  ################################################################################

  #######
  #private method to clean up number
  def cleanFloatNum

    num = shift
    num = sprintf("%0.#{g_fltlen}f",num)
    num.sub!(/([1-9])0+$/, '$1')
    num.sub!(/(\d)\.0+$/, '$1')
    num
  end
  ################################################################################

  # == fileNum - file number...
  # 
  #   usage:
  # 

  def fileNum (*arg)

    
    int(@Fd)
  end
  ################################################################################

  # == close - close gds2 file
  # 
  #   usage:
  #   $gds2File -> close;
  #    -or-
  #   $gds2File -> close(-markEnd=>1); ## -- some systems have trouble closing files
  #   $gds2File -> close(-pad=>2048);  ## -- pad end with \0's till file size is a
  #                                    ## multiple of number. Note: old reel to reel tapes on Calma
  #                                    ## systems used 2048 byte blocks
  # 

  def close (*arg)

    
    markEnd = arg['-markEnd']
    pad = arg['-pad']
    if  ( markEnd)&&(markEnd) 
      
      fh = @FileHandle
      fh.print "\x1a\x04"; # a ^Z and a ^D
      @BytesDone += 2
    end
    if  ( pad)&&(pad > 0) 
      
      fh = @FileHandle
      fh.flush
      seek(fh,0,SEEK_END)
      fileSize = tell(fh)
      padSize = pad - (fileSize % pad)
      padSize = 0 if padSize == pad 
      (0..padSize).each do |i|
        fh.print "\0" ## a null
      end
    end
    @FileHandle . close
  end
  ################################################################################

  ################################################################################

  # = High Level Write Methods
  # 

  ################################################################################

  # == printInitLib() - Does all the things needed to start a library, writes HEADER,BGNLIB,LIBNAME,and UNITS records
  # 
  # The default is to create a library with a default unit of 1 micron that has a resolution of 1000. To get this set uUnit to 0.001 (1/1000) and the dbUnit to 1/1000th of a micron (1e-9).
  #    usage:
  #      $gds2File -> printInitLib(-name    => "testlib",  ## required
  #                                -isoDate => 0|1         ## (optional) use ISO 4 digit date 2001 vs 101
  #                                -uUnit   => real number ## (optional) default is 0.001
  #                                -dbUnit  => real number ## (optional) default is 1e-9
  #                               );
  # 
  #      ## defaults to current date for library date
  # 
  #    note:
  #      remember to close library with printEndlib()
  # 

  def printInitLib (name = nil, isoDate = false, uunit = false, dbUnit = 1e-9)

    
    unless name 
      raise "printInitLib expects a library name. Missing -name => 'name' $!"
    end
    #################################################
    if !uUnit 
      uUnit = 0.001
    else
      @Resolution = cleanFloatNum(1 / uUnit); ## default is 1000 - already set in new()
    end
    @UUnits = uUnit

    #################################################
    @DBUnits = dbUnit
    #################################################

    (sec,min,hour,mday,mon,year,wday,yday,isdst) = localtime(time)
    mon+=1
    year += 1900 if  isoDate ; ## Cadence likes year left "as is". GDS format supports year number up to 65535 -- 101 vs 2001
    self.printGds2Record('-type' => 'HEADER','-data' => 3); ## GDS2 HEADER
    self.printGds2Record('-type' => 'BGNLIB','-data' => [year,mon,mday,hour,min,sec,year,mon,mday,hour,min,sec])
    self.printGds2Record('-type' => 'LIBNAME','-data' => name)
    self.printGds2Record('-type' => 'UNITS','-data' => [uUnit,dbUnit])
  end
  ################################################################################

  # == printBgnstr - Does all the things needed to start a structure definition
  # 
  #    usage:
  #     $gds2File -> printBgnstr(-name => "nand3" ## writes BGNSTR and STRNAME records
  #                              -isoDate => 1|0  ## (optional) use ISO 4 digit date 2001 vs 101
  #                              );
  # 
  #    note:
  #      remember to close with printEndstr()
  # 

  def printBgnstr (isoDate = false, *arg)

    

    strName = arg['-name']
    unless   strName 
      
      raise "bgnStr expects a structure name. Missing -name => 'name' $!"
    end
    createTime = arg['-createTime']
    isoDate = arg['-isoDate']
    csec,cmin,chour,cmday,cmon,cyear,cwday,cyday,cisdst = 0,0,0,0,0,0,0,0,0
    if   createTime 
      
      csec,cmin,chour,cmday,cmon,cyear,cwday,cyday,cisdst = localtime(createTime)
      
    else
      
      csec,cmin,chour,cmday,cmon,cyear,cwday,cyday,cisdst = localtime(time)
    end
    cmon+=1

    modTime = arg['-modTime']

    msec,mmin,mhour,mmday,mmon,myear,mwday,myday,misdst = 0,0,0,0,0,0,0,0,0
    if   modTime 
      msec,mmin,mhour,mmday,mmon,myear,mwday,myday,misdst = localtime(modTime)
      
    else
      
      msec,mmin,mhour,mmday,mmon,myear,mwday,myday,misdst = localtime(time)
    end
    mmon+=1

    if  isoDate 
      cyear += 1900;  ## 2001 vs 101
      myear += 1900
    end
    self.printGds2Record('-type' => 'BGNSTR','-data' => [cyear,cmon,cmday,chour,cmin,csec,myear,mmon,mmday,mhour,mmin,msec])
    self.printGds2Record('-type' => 'STRNAME','-data' => strName)
  end
  ################################################################################

  # == printPath - prints a gds2 path
  # 
  #   usage:
  #     $gds2File -> printPath(
  #                     -layer=>#,
  #                     -dataType=>#,     ##optional
  #                     -pathType=>#,
  #                     -width=>#.#,
  #                     -unitWidth=>#,    ## (optional) directly specify width in data base units (vs -width which is multipled by resolution)
  # 
  #                     -xy=>\@array,     ## array of reals
  #                       # -or-
  #                     -xyInt=>\@array,  ## array of internal ints (optional -wks better if you are modifying an existing GDS2 file)
  #                   );
  # 
  #   note:
  #     layer defaults to 0 if -layer not used
  #     pathType defaults to 0 if -pathType not used
  #       pathType 0 = square end
  #                1 = round end
  #                2 = square - extended 1/2 width
  #                4 = custom plus variable path extension...
  #     width defaults to 0.0 if -width not used
  # 

  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  #  <path>::= PATH [ELFLAGS] [PLEX] LAYER DATATYPE [PATHTYPE] [WIDTH] XY
  def printPath (*arg)

    
    resolution= @Resolution
    layer = arg['-layer']
    layer=0 unless    layer 

    dataType = arg['-dataType']
    dataType=0 unless   dataType 

    pathType = arg['-pathType']
    pathType=0 unless   pathType 

    bgnExtn = arg['-bgnExtn']
    bgnExtn=0 unless   bgnExtn 

    endExtn = arg['-endExtn']
    endExtn=0 unless   endExtn 

    unitWidth = arg['-unitWidth']
    widthReal = arg['-width']
    width = 0
    if  ( unitWidth)&&(unitWidth >= 0) 
      
      width=int(unitWidth)
    end
    if  ( widthReal)&&(widthReal >= 0.0) 
      
      width = int((widthReal*resolution)+g_epsilon)
    end
    #### -xyInt most useful if reading and modifying... -xy if creating from scratch
    xyInt = arg['-xyInt']; ## $xyInt should be a reference to an array of internal GDS2 format integers
    xy = arg['-xy'];       ## $xy should be a reference to an array of reals
    xyTmp=[];               ##don't pollute array passed in
    if  ! (( xy) || ( xyInt)) 
      
      raise "printPath expects an xy array reference. Missing -xy => \\\#{array} $!"
    end
    if   xyInt 
      
      xy = xyInt
      resolution=1
    end
    self.printGds2Record('-type' => 'PATH')
    self.printGds2Record('-type' => 'LAYER','-data' => layer)
    self.printGds2Record('-type' => 'DATATYPE','-data' => dataType)
    self.printGds2Record('-type' => 'PATHTYPE','-data' => pathType) if  pathType 
    self.printGds2Record('-type' => 'WIDTH','-data' => width) if  width 
    if  pathType == 4 
      self.printGds2Record('-type' => 'BGNEXTN','-data' => bgnExtn); ## int used with resolution
      self.printGds2Record('-type' => 'ENDEXTN','-data' => endExtn); ## int used with resolution
    end

    xy.each do |xyi|
      ## e.g. 3.4 in -> 3400 out
      if  xyi >= 0
        xyTmp << int(((xyi)*resolution)+g_epsilon);
      else
        xyTmp << int(((xyi)*resolution)-g_epsilon);
      end
    end
    
    if  bgnExtn || endExtn  ## we have to convert
      
      bgnX1 = xyTmp[0]
      bgnY1 = xyTmp[1]
      bgnX2 = xyTmp[2]
      bgnY2 = xyTmp[3]
      endX1 = xyTmp[xyTmp.length - 1]
      endY1 = xyTmp[xyTmp.length]
      endX2 = xyTmp[xyTmp.length - 3]
      endY2 = xyTmp[xyTmp.length - 2]
      if  bgnExtn 
        
        if  bgnX1 == bgnX2  #vertical ...modify 1st Y
          
          if  bgnY1 < bgnY2  ## points down
            
            xyTmp[1] -= bgnExtn
            xyTmp[1] += int(width/2) if  pathType != 0 
            
          else ## points up
            
            xyTmp[1] += bgnExtn
            xyTmp[1] -= int(width/2) if  pathType != 0 
          end
          
        elsif  bgnY1 == bgnY2  #horizontal ...modify 1st X
          
          if  bgnX1 < bgnX2  ## points left
            
            xyTmp[0] -= bgnExtn
            xyTmp[0] += int(width/2) if  pathType != 0 
            
          else ## points up
            
            xyTmp[0] += bgnExtn
            xyTmp[0] -= int(width/2) if  pathType != 0 
          end
        end
      end

      if  endExtn 
        
        if  endX1 == endX2  #vertical ...modify last Y
          
          if  endY1 < endY2  ## points down
            
            xyTmp[xyTmp.length] -= endExtn
            xyTmp[xyTmp.length] += int(width/2) if  pathType != 0 
            
          else ## points up
            
            xyTmp[xyTmp.length] += endExtn
            xyTmp[xyTmp.length] -= int(width/2) if  pathType != 0 
          end
          
        elsif  endY1 == endY2  #horizontal ...modify last X
          
          if  endX1 < endX2  ## points left
            
            xyTmp[xyTmp.length - 1] -= endExtn
            xyTmp[xyTmp.length - 1] += int(width/2) if  pathType != 0 
            
          else ## points up
            
            xyTmp[xyTmp.length - 1] += endExtn
            xyTmp[xyTmp.length - 1] -= int(width/2) if  pathType != 0 
          end
        end
      end
    end
    self.printGds2Record('-type' => 'XY','-data' => xyTmp)
    self.printGds2Record('-type' => 'ENDEL')
  end
  ################################################################################

  # == printBoundary - prints a gds2 boundary
  # 
  #   usage:
  #     $gds2File -> printBoundary(
  #                     -layer=>#,
  #                     -dataType=>#,
  # 
  #                     -xy=>\@array,     ## ref to array of reals
  #                       # -or-
  #                     -xyInt=>\@array,  ## ref to array of internal ints (optional -wks better if you are modifying an existing GDS2 file)
  #                  );
  # 
  #   note:
  #     layer defaults to 0 if -layer not used
  #     dataType defaults to 0 if -dataType not used
  # 

  #  <boundary>::= BOUNDARY [ELFLAGS] [PLEX] LAYER DATATYPE XY
  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  def printBoundary (*arg)

    
    resolution= @Resolution
    layer = arg['-layer']
    layer = 0 unless   layer 
    dataType = arg['-dataType']
    dataType=0 unless   dataType 
    #### -xyInt most useful if reading and modifying... -xy if creating from scratch
    xyInt = arg['-xyInt']; ## $xyInt should be a reference to an array of internal GDS2 format integers
    xy = arg['-xy']; ## $xy should be a reference to an array of reals
    xyTmp = []; ##don't pollute array passed in
    unless  (xy) || (xyInt) 
      
      raise "printBoundary expects an xy array reference. Missing -xy => \\\#{array} $!"
    end
    if   xyInt 
      
      xy = xyInt
      resolution=1
    end
    self.printGds2Record('-type' => 'BOUNDARY')
    self.printGds2Record('-type' => 'LAYER','-data' => layer)
    self.printGds2Record('-type' => 'DATATYPE','-data' => dataType)
    if  (numPoints = xy.length+1) < 6 
      
      raise "printBoundary expects an xy array of at leasts 3 coordinates $!"
    end
    xy.each do |xyi|
      ## e.g. 3.4 in -> 3400 out
      
      if  xyi >= 0
        xyTmp.push int(((xyi)*resolution)+g_epsilon);
      else
        xyTmp.push int(((xyi)*resolution)-g_epsilon)
      end
    end
    ## gds expects square to have 5 coords (closure)
    if  (xy[0] != (xy[(xy.length - 1)])) || (xy[1] != (xy[xy.length])) 
      
      if  xy[0] >= 0
        xyTmp.push int(((xy[0])*resolution)+g_epsilon);
      else
        xyTmp.push int(((xy[0])*resolution)-g_epsilon)
      end
      if  xy[1] >= 0
        xyTmp.push int(((xy[1])*resolution)+g_epsilon);
      else
        xyTmp.push int(((xy[1])*resolution)-g_epsilon)
      end
    end
    self.printGds2Record('-type' => 'XY','-data' => xyTmp)
    self.printGds2Record('-type' => 'ENDEL')
  end
  ################################################################################

  # == printSref - prints a gds2 Structure REFerence
  # 
  #   usage:
  #     $gds2File -> printSref(
  #                     -name=>string,   ## Name of structure
  # 
  #                     -xy=>\@array,    ## ref to array of reals
  #                       # -or-
  #                     -xyInt=>\@array, ## ref to array of internal ints (optional -wks better than -xy if you are modifying an existing GDS2 file)
  # 
  #                     -angle=>#.#,     ## (optional) Default is 0.0
  #                     -mag=>#.#,       ## (optional) Default is 1.0
  #                     -reflect=>0|1    ## (optional)
  #                  );
  # 
  #   note:
  #     best not to specify angle or mag if not needed
  # 

  #<SREF>::= SREF [ELFLAGS] [PLEX] SNAME [<strans>] XY
  #  <strans>::=   STRANS [MAG] [ANGLE]
  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  def printSref (*arg)

    
    useSTRANS=FALSE
    resolution= @Resolution
    sname = arg['-name']
    unless   sname 
      
      raise "printSref expects a name string. Missing -name => 'text' $!"
    end
    #### -xyInt most useful if reading and modifying... -xy if creating from scratch
    xyInt = arg['-xyInt']; ## $xyInt should be a reference to an array of internal GDS2 format integers
    xy = arg['-xy']; ## $xy should be a reference to an array of reals
    unless  (xy) || (xyInt) 
      
      raise "printSref expects an xy array reference. Missing -xy => \\\#{array} $!"
    end
    if   xyInt 
      
      xy = xyInt
      resolution=1
    end
    self.printGds2Record('-type' => 'SREF')
    self.printGds2Record('-type' => 'SNAME','-data' => sname)
    reflect = arg['-reflect']
    if  (!  reflect)||(reflect <= 0) 
      
      reflect = 0
      
    else
      
      reflect = 1
      useSTRANS = TRUE
    end
    mag = arg['-mag']
    if  (!  mag)||(mag <= 0) 
      
      mag=0
      
    else
      
      mag = cleanFloatNum(mag)
      useSTRANS=TRUE
    end
    angle = arg['-angle']
    if  !  angle 
      
      angle = -1; #not really... just means not specified
      
    else
      
      angle = posAngle(angle)
      useSTRANS = TRUE
    end
    if  useSTRANS 
      
      data = reflect+'0'*15; ## 16 'bit' string
      self.printGds2Record('-type' => 'STRANS','-data' => data)
      self.printGds2Record('-type' => 'MAG','-data' => mag) if  mag 
      self.printGds2Record('-type' => 'ANGLE','-data' => angle) if  angle >= 0 
    end
    xyTmp=[]; ##don't pollute array passed in
    xy.each do |xyi| ## e.g. 3.4 in -> 3400 out
      
      if  xyi >= 0
        xyTmp << int(((xyi)*resolution)+g_epsilon);
      else
        xyTmp << int(((xyi)*resolution)-g_epsilon)
      end
    end
    self.printGds2Record('-type' => 'XY','-data' => xyTmp)
    self.printGds2Record('-type' => 'ENDEL')
  end
  ################################################################################

  # == printAref - prints a gds2 Array REFerence
  # 
  #   usage:
  #     $gds2File -> printAref(
  #                     -name=>string,   ## Name of structure
  #                     -columns=>#,     ## Default is 1
  #                     -rows=>#,        ## Default is 1
  # 
  #                     -xy=>\@array,    ## ref to array of reals
  #                       # -or-
  #                     -xyInt=>\@array, ## ref to array of internal ints (optional -wks better if you are modifying an existing GDS2 file)
  # 
  #                     -angle=>#.#,     ## (optional) Default is 0.0
  #                     -mag=>#.#,       ## (optional) Default is 1.0
  #                     -reflect=>0|1    ## (optional)
  #                  );
  # 
  #   note:
  #     best not to specify angle or mag if not needed
  #     xyList: 1st coord: origin, 2nd coord: X of col * xSpacing + origin, 3rd coord: Y of row * ySpacing + origin
  # 

  #<AREF>::= AREF [ELFLAGS] [PLEX] SNAME [<strans>] COLROW XY
  #  <strans>::= STRANS [MAG] [ANGLE]
  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  def printAref (*arg)

    
    useSTRANS=FALSE
    resolution= @Resolution
    sname = arg['-name']
    unless   sname 
      
      raise "printAref expects a sname string. Missing -name => 'text' $!"
    end
    #### -xyInt most useful if reading and modifying... -xy if creating from scratch
    xyInt = arg['-xyInt']; ## $xyInt should be a reference to an array of internal GDS2 format integers
    xy = arg['-xy']; ## $xy should be a reference to an array of reals
    unless  (xy) || (xyInt) 
      
      raise "printAref expects an xy array reference. Missing -xy => \\\#{array} $!"
    end
    if   xyInt 
      
      xy = xyInt
      resolution=1
    end
    self.printGds2Record('-type' => 'AREF')
    self.printGds2Record('-type' => 'SNAME','-data' => sname)
    reflect = arg['-reflect']
    if  (!  reflect)||(reflect <= 0) 
      
      reflect = 0
      
    else
      
      reflect = 1
      useSTRANS=TRUE
    end
    mag = arg['-mag']
    if  (!  mag)||(mag <= 0) 
      
      mag = 0
      
    else
      
      mag = cleanFloatNum(mag)
      useSTRANS=TRUE
    end
    angle = arg['-angle']
    if  !  angle 
      
      angle = -1; #not really... just means not specified
      
    else
      
      angle = posAngle(angle)
      useSTRANS = TRUE
    end
    if  useSTRANS 
      
      data=reflect+'0'*15; ## 16 'bit' string
      self.printGds2Record('-type' => 'STRANS','-data' => data)
      self.printGds2Record('-type' => 'MAG','-data' => mag) if  mag 
      self.printGds2Record('-type' => 'ANGLE','-data' => angle) if  angle >= 0 
    end
    columns = arg['-columns']
    if  (!  columns)||(columns <= 0) 
      
      columns=1
      
    else
      
      columns = int(columns)
    end
    rows = arg['-rows']
    if  (!  rows)||(rows <= 0) 
      
      rows=1
      
    else
      
      rows = int(rows)
    end
    self.printGds2Record('-type' => 'COLROW','-data' => [columns,rows])
    xyTmp=[]; ##don't pollute array passed in
    xy.each do |xyi| ## e.g. 3.4 in -> 3400 out
      
      if  xyi >= 0
        xyTmp << int(((xyi)*resolution)+g_epsilon);
      else
        xyTmp << int(((xyi)*resolution)-g_epsilon);end
    end
    self.printGds2Record('-type' => 'XY','-data' => xyTmp)
    self.printGds2Record('-type' => 'ENDEL')
  end
  ################################################################################

  # == printText - prints a gds2 Text
  # 
  #   usage:
  #     $gds2File -> printText(
  #                     -string=>string,
  #                     -layer=>#,      ## Default is 0
  #                     -textType=>#,   ## Default is 0
  #                     -font=>#,       ## 0-3
  #                     -top, or -middle, -bottom,     ##optional vertical presentation
  #                     -left, or -center, or -right,  ##optional horizontal presentation
  # 
  #                     -xy=>\@array,     ## ref to array of reals
  #                       # -or-
  #                     -xyInt=>\@array,  ## ref to array of internal ints (optional -wks better if you are modifying an existing GDS2 file)
  # 
  #                     -x=>#.#,          ## optional way of passing in x value
  #                     -y=>#.#,          ## optional way of passing in y value
  #                     -angle=>#.#,      ## (optional) Default is 0.0
  #                     -mag=>#.#,        ## (optional) Default is 1.0
  #                     -reflect=>#,      ## (optional) Default is 0
  #                  );
  # 
  #   note:
  #     best not to specify reflect, angle or mag if not needed
  # 

  #<text>::= TEXT [ELFLAGS] [PLEX] LAYER <textbody>
  #  <textbody>::= TEXTTYPE [PRESENTATION] [PATHTYPE] [WIDTH] [<strans>] XY STRING
  #    <strans>::= STRANS [MAG] [ANGLE]
  ################################################################################
  def printText (*arg)

    
    useSTRANS = FALSE
    string = arg['-string']
    unless   string 
      
      raise "printText expects a string. Missing -string => 'text' $!"
    end
    resolution= @Resolution
    x = arg['-x']
    y = arg['-y']
    #### -xyInt most useful if reading and modifying... -xy if creating from scratch
    xyInt = arg['-xyInt']; ## $xyInt should be a reference to an array of internal GDS2 format integers
    xy = arg['-xy']; ## $xy should be a reference to an array of reals
    if   xyInt 
      
      xy = xyInt
      resolution=1
    end
    if   xy 
      
      x= xy[0]
      y= xy[1]
    end

    x2 = arg['-x']
    if   x2 
      
      x = x2
    end
    unless   x 
      
      raise "printText expects a x coord. Missing -xy=>\#{array} or -x => 'num' $!"
    end
    if  x>=0
      x = int((x*resolution)+g_epsilon);
    else
      x = int((x*resolution)-g_epsilon);end

    y2 = arg['-y']
    if   y2 
      
      y = y2
    end
    unless   y 
      
      raise "printText expects a y coord. Missing -xy=>\#{array} or -y => 'num' $!"
    end
    if  y>=0
      y = int((y*resolution)+g_epsilon);
    else
      y = int((y*resolution)-g_epsilon);
    end

    layer = arg['-layer']
    layer = 0 unless   layer 
    textType = arg['-textType']
    textType=0 unless   textType 
    reflect = arg['-reflect']
    if  (!  reflect)||(reflect <= 0) 
      
      reflect = 0
      
    else
      
      reflect = 1
      useSTRANS = TRUE
    end

    font = arg['-font']
    if  (!  font) || (font < 0) || (font > 3) 
      
      font = 0
    end
    font = sprintf("%02d",font)

    vertical
    top = arg['-top']
    middle = arg['-middle']
    bottom = arg['-bottom']
    if top
      vertical = '00'
    elsif bottom
      vertical = '10'
    else
      vertical = '01'
    end ## middle
    horizontal
    left   = arg['-left']
    center = arg['-center']
    right  = arg['-right']
    if      left   ; horizontal = '00'
    elsif   right  ; horizontal = '10'
    else           ; horizontal = '01'
    end ## center
    presString = '0'*10
    presString += "#{font}#{vertical}#{horizontal}"

    mag = arg['-mag']
    if  (!  mag)||(mag <= 0) 
      mag=0
    else
      
      mag = cleanFloatNum(mag)
    end
    angle = arg['-angle']
    if  !  angle 
      
      angle = -1; #not really... just means not specified
      
    else
      
      angle=posAngle(angle)
    end
    self.printGds2Record('-type'=>'TEXT')
    self.printGds2Record('-type'=>'LAYER','-data'=>layer)
    self.printGds2Record('-type'=>'TEXTTYPE','-data'=>textType)
    self.printGds2Record('-type' => 'PRESENTATION','-data' => presString) if   font ||  top ||  middle ||  bottom ||  bottom ||  left ||  center ||  right 
    if  useSTRANS 
      
      data=reflect+'0'*15; ## 16 'bit' string
      self.printGds2Record('-type'=>'STRANS','-data'=>data)
    end
    self.printGds2Record('-type'=>'MAG','-data'=>mag) if  mag 
    self.printGds2Record('-type'=>'ANGLE','-data'=>angle) if  angle >= 0 
    self.printGds2Record('-type'=>'XY','-data'=>[x,y])
    self.printGds2Record('-type'=>'STRING','-data'=>string)
    self.printGds2Record('-type'=>'ENDEL')
  end
  ################################################################################

  # = Low Level Generic Write Methods
  # 

  ################################################################################

  # ==  saveGds2Record() - low level method to create a gds2 record given record type
  #   and data (if required). Data of more than one item should be given as a list.
  # 
  #   NOTE: THIS ONLY USES GDS2 OBJECT TO GET RESOLUTION
  # 
  #   usage:
  #     saveGds2Record(
  #             -type=>string,
  #             -data=>data_If_Needed, ##optional for some types
  #             -scale=>#.#,           ##optional number to scale data to. I.E -scale=>0.5 #default is NOT to scale
  #             -snap=>#.#,            ##optional number to snap data to I.E. -snap=>0.005 #default is 1 resolution unit, typically 0.001
  #     );
  # 
  #   examples:
  #     my $gds2File = new GDS2(-fileName => ">$fileName");
  #     my $record = $gds2File -> saveGds2Record(-type=>'header',-data=>3);
  #     $gds2FileOut -> printGds2Record(-type=>'record',-data=>$record);
  # 
  # 

  def saveGds2Record (*arg)

    
    record = ''

    type = arg['-type']
    if  !  type 
      
      raise "saveGds2Record expects a type name. Missing -type => 'name' $!"
      
    else
      
      type = uc type
    end

    saveEnd = $\
                $\ = ''

    data = arg['-data']
    dataString = arg['-asciiData']
    raise "saveGds2Record can not handle both -data and -asciiData options $!" if  ( dataString)&&(( data[0])&&(data[0] != '')) 

    data = ''
    if  type == 'RECORD'  ## special case...
      
      return data[0]
      
    else
      
      numDataElements = 0
      resolution= @Resolution

      scale = arg['-scale']
      if  !  scale 
        
        scale = 1
      end
      if  scale <= 0 
        
        raise "saveGds2Record expects a positive scale -scale => #{scale} $!"
      end

      snap = arg['-snap']
      if  !  snap  ## default is one resolution unit
        
        snap = 1
        
      else
        
        snap = snap*resolution; ## i.e. 0.001 -> 1
      end
      if  snap < 1 
        
        raise "saveGds2Record expects a snap >= 1/resolution -snap => #{snap} $!"
      end

      if  ( data[0])&&(data[0] != '') 
        
        data = data[0]
        numDataElements = @data
        if  numDataElements  ## passed in anonymous array
          
          data = @data; ## deref
          
        else
          
          numDataElements = data
        end
      end

      recordDataType = recordtypedata[type]
      if   dataString 
        
        dataString.sub!(/^\s+/, ''); ## clean-up
        dataString.sub!(/\s+$/, '')
        dataString.gsub!(/\s+/, ' ') if  dataString !~ %r|'| ; ## don't compress spaces in strings...
        dataString.sub!(/'$/, ''); #'for strings
        dataString.sub!(/^'/, ''); #'for strings
        if  (recordDataType == BIT_ARRAY)||(recordDataType == ASCII_STRING) 
          
          data = dataString
          
        else
          
          dataString.gsub!(/\s*[\s,;:\/\\]+\s*/, ' '); ## incase commas etc... (non-std) were added by hand
          data = split(' ',dataString)
          numDataElements = data
          if  recordDataType == INTEGER_4 
            
            xyTmp = []
            (0..numDatatElements-1).each do |i| ## e.g. 3.4 in -> 3400 out
              if  data[i]>=0
                xyTmp << int(((data[i])*resolution)+g_epsilon)
              else
                xyTmp << int(((data[i])*resolution)-g_epsilon)
              end
            end
            data=xyTmp
          end
        end
      end
      byte
      length = 0
      if  recordDataType == BIT_ARRAY 
        
        length = 2
        
      elsif  recordDataType == INTEGER_2 
        
        length = 2 * numDataElements
        
      elsif  recordDataType == INTEGER_4 
        
        length = 4 * numDataElements
        
      elsif  recordDataType == REAL_8 
        
        length = 8 * numDataElements
        
      elsif  recordDataType == ASCII_STRING 
        
        slen = length data
        length = slen + (slen % 2); ## needs to be an even number
      end

      recordLength = pack 'S',(length + 4); #1 2 bytes for length 3rd for recordType 4th for dataType
      record += recordLength
      recordType = pack 'C',recordtypenumbers[type]
      record += recordType

      dataType   = pack 'C',recordtypedata[type]
      record += dataType

      if  recordDataType == BIT_ARRAY      ## bit array
        
        bitLength = length * 8
        record += pack("B#{bitLength}",data)
        
      elsif  recordDataType == INTEGER_2   ## 2 byte signed integer
        
        data.each do |num|
          record += pack('s',num)
        end
        
      elsif  recordDataType == INTEGER_4   ## 4 byte signed integer
        
        data.each do |num|
          num = scaleNum(num,scale) if  scale != 1 
          num = snapNum(num,snap) if  snap != 1 
          record += pack('i',num)
        end
        
      elsif  recordDataType == REAL_8   ## 8 byte real
        
        data.each do |num|
          real = num
          negative = FALSE
          if num < 0.0 
            
            negative = TRUE
            real = 0 - num
          end

          exponent = 0
          while real >= 1.0 
            
            exponent+=1
            real = (real / 16.0)
          end

          if  real != 0 
            
            while real < 0.0625 
              
              --exponent
              real = (real * 16.0)
            end
          end

          if negative
            exponent += 192; 
          else
            exponent += 64; end
          record += pack('C',exponent)

          (1..7).each do |i|
            if  real>=0
              byte = int((real*256.0)+g_epsilon);
            else
              byte = int((real*256.0)-g_epsilon);
            end
            record += pack('C',byte)
            real = real * 256.0 - (byte + 0.0)
          end
        end
        
      elsif  recordDataType == ASCII_STRING   ## ascii string (null padded)
        
        record += pack("a#{length}",data)
      end
    end
    $\=saveEnd
    record
  end
  ################################################################################

  # ==  printGds2Record() - low level method to print a gds2 record given record type
  #   and data (if required). Data of more than one item should be given as a list.
  # 
  #   usage:
  #     printGds2Record(
  #             -type=>string,
  #             -data=>data_If_Needed, ##optional for some types
  #             -scale=>#.#,           ##optional number to scale data to. I.E -scale=>0.5 #default is NOT to scale
  #             -snap=>#.#,            ##optional number to snap data to I.E. -snap=>0.005 #default is 1 resolution unit, typically 0.001
  #     );
  # 
  #   examples:
  #     my $gds2File = new GDS2(-fileName => ">$fileName");
  # 
  #     $gds2File -> printGds2Record(-type=>'header',-data=>3);
  #     $gds2File -> printGds2Record(-type=>'bgnlib',-data=>[99,12,1,22,33,0,99,12,1,22,33,9]);
  #     $gds2File -> printGds2Record(-type=>'libname',-data=>"testlib");
  #     $gds2File -> printGds2Record(-type=>'units',-data=>[0.001, 1e-9]);
  #     $gds2File -> printGds2Record(-type=>'bgnstr',-data=>[99,12,1,22,33,0,99,12,1,22,33,9]);
  #     ...
  #     $gds2File -> printGds2Record(-type=>'endstr');
  #     $gds2File -> printGds2Record(-type=>'endlib');
  # 
  #   Note: the special record type of 'record' can be used to copy a complete record
  #   just read in:
  #     while (my $record = $gds2FileIn -> readGds2Record())
  #     {
  #         $gds2FileOut -> printGds2Record(-type=>'record',-data=>$record);
  #     }
  # 

  def printGds2Record (*arg)

    

    type = arg['-type']
    unless   type 
      
      raise "printGds2Record expects a type name. Missing -type => 'name' $!"
      
    else
      
      type = uc type
    end
    data = arg['-data']
    dataString = arg['-asciiData']
    raise "printGds2Record can not handle both -data and -asciiData options $!" if  ( dataString)&&(( data[0])&&(data[0] != '')) 

    fh= @FileHandle
    saveEnd=$\
              $\=''

    data = ''
    data = [] unless   data[0] 
    recordLength; ## 1st 2 bytes for length 3rd for recordType 4th for dataType
    if  type == 'RECORD'  ## special case...
      
      if  @isLittleEndian 
        
        length = substr(data[0],0,2)
        recordLength = unpack 'v',length
        @BytesDone += recordLength
        length = reverse length
        fh.print( length)

        recordType = substr(data[0],2,1)
        fh.print( recordType)
        recordType = unpack 'C',recordType
        type = recordtypestrings[recordType]; ## will use code below.....

        dataType = substr(data[0],3,1)
        fh.print( dataType)
        dataType = unpack 'C',dataType
        if  recordLength > 4 
          
          lengthLeft = recordLength - 4; ## length left
          recordDataType = recordtypedata[type]

          if  (recordDataType == INTEGER_2) || (recordDataType == BIT_ARRAY) 
            
            binData = unpack 'b*',data[0]
            intData = substr(binData,32); #skip 1st 4 bytes (length, recordType dataType)

            byteInt2String,byte2 = nil, nil
            (0..lengthLeft/2-1).each do |i|
              byteInt2String = reverse(substr(intData,0,16,''))
              byte2=pack 'B16',reverse(byteInt2String)
              fh.print( byte2)
            end
            
          elsif  recordDataType == INTEGER_4 
            
            binData = unpack 'b*',data[0]
            intData = substr(binData,32); #skip 1st 4 bytes (length, recordType dataType)
            #(byteInt4String,byte4)
            (0..lengthLeft/4-1).each do |i|
              
              byteInt4String = reverse(substr(intData,0,32,''))
              byte4=pack 'B32',reverse(byteInt4String)
              fh.print byte4
            end
            
          elsif  recordDataType == REAL_8 
            
            binData = unpack 'b*',data[0]
            realData = substr(binData,32); #skip 1st 4 bytes (length, recordType dataType)
            #(bit64String,mantissa,byteString,byte)
            (0..lengthLeft/8-1).each do |i|
              bit64String = substr(realData,(i*64),64)
              fh.print( pack 'b8',bit64String)
              mantissa = substr(bit64String,8,56)
              (0..6).each do |j|
                byteString = substr(mantissa,(j*8),8)
                byte=pack 'b8',byteString
                fh.print(byte)
              end
            end
            
          elsif  recordDataType == ASCII_STRING   ## ascii string (null padded)
            
            fh.print pack("a#{lengthLeft}",substr(data[0],4))
            
          elsif  recordDataType == REAL_4   ## 4 byte real
            
            raise "4-byte reals are not supported $!"
          end
        end
        
      else
        
        fh.print( data[0])
        recordLength = length data[0]
        @BytesDone += recordLength
      end
      
    else #if ($type ne 'RECORD')
      
      numDataElements = 0
      resolution= @Resolution
      uUnits= @UUnits

      scale = arg['-scale']
      if  !  scale 
        
        scale = 1
      end
      if  scale <= 0 
        
        raise "printGds2Record expects a positive scale -scale => #{scale} $!"
      end

      snap = arg['-snap']
      if  !  snap  ## default is one resolution unit
        
        snap = 1
        
      else
        
        snap = int((snap*resolution)+g_epsilon); ## i.e. 0.001 -> 1
      end
      if  snap < 1 
        
        raise "printGds2Record expects a snap >= 1/resolution -snap => #{snap} $!"
      end

      if  ( data[0])&&(data[0] != '') 
        
        data = data[0]
        numDataElements = @data
        if  numDataElements  ## passed in anonymous array
          
          data = @data; ## deref
          
        else
          
          numDataElements = data
        end
      end

      recordDataType = recordtypedata[type]

      if   dataString 
        
        dataString.sub!(/^\s+/, ''); ## clean-up
        dataString.sub!(/\s+$/, '')
        dataString.gsub!(/\s+/, ' ') if  dataString !~ %r|'| ; ## don't compress spaces in strings...
        dataString.sub!(/'$/, ''); #'# for strings
        dataString.sub!(/^'/, ''); #'# for strings
        if  (recordDataType == BIT_ARRAY)||(recordDataType == ASCII_STRING) 
          
          data = dataString
          
        else
          
          dataString.gsub!(/\s*[\s,;:\/\\]+\s*/, ' '); ## in case commas etc... (non-std) were added by hand
          data = split(' ',dataString)
          numDataElements = data
          if  recordDataType == INTEGER_4 
            
            xyTmp=[]
            (0..numDataElements-1).each do |i| ## e.g. 3.4 in -> 3400 out
              
              if  data[i]>=0
                xyTmp << int(((data[i])*resolution)+g_epsilon);
              else
                xyTmp << int(((data[i])*resolution)-g_epsilon)
              end
            end
            data=xyTmp
          end
        end
      end
      byte = nil
      length = 0
      if  recordDataType == BIT_ARRAY 
        
        length = 2
        
      elsif  recordDataType == INTEGER_2 
        
        length = 2 * numDataElements
        
      elsif  recordDataType == INTEGER_4 
        
        length = 4 * numDataElements
        
      elsif  recordDataType == REAL_8 
        
        length = 8 * numDataElements
        
      elsif  recordDataType == ASCII_STRING 
        
        slen = length data
        length = slen + (slen % 2); ## needs to be an even number
      end
      @BytesDone += length

      if  @isLittleEndian 
        recordLength = pack 'v',(length + 4)
        recordLength = reverse recordLength
      else
        recordLength = pack 'S',(length + 4)
      end
      fh.print( recordLength)

      recordType = pack 'C',recordtypenumbers[type]
      recordType = reverse recordType if  @isLittleEndian 
      fh.print( recordType)

      dataType = pack 'C',recordtypedata[type]
      dataType = reverse dataType if  @isLittleEndian 
      fh.print( dataType)

      if  recordDataType == BIT_ARRAY      ## bit array
        
        bitLength = length * 8
        value = pack("B#{bitLength}",data)
        fh.print(value)
        
      elsif  recordDataType == INTEGER_2   ## 2 byte signed integer
        
        #value
        data.each do |num|
          
          value = pack('s',num)
          value = reverse value if  @isLittleEndian 
          fh.print( value)
        end
        
      elsif  recordDataType == INTEGER_4   ## 4 byte signed integer
        
        #value
        data.each do |num|
          num = scaleNum(num,scale) if  scale != 1 
          num = snapNum(num,snap) if  snap != 1 
          value = pack('i',num)
          value = reverse value if  @isLittleEndian 
          fh.print( value)
        end
        
      elsif  recordDataType == REAL_8   ## 8 byte real
        
        # (real,negative,exponent,value)
        data.each do |num|
          
          real = num
          negative = FALSE
          if num < 0.0 
            
            negative = TRUE
            real = 0 - num
          end

          exponent = 0
          while real >= 1.0 
            
            exponent+=1
            real = (real / 16.0)
          end

          if  real != 0 
            
            while real < 0.0625 
              
              --exponent
              real = (real * 16.0)
            end
          end
          if negative   exponent += 192; 
          else           exponent += 64; end
          value = pack('C',exponent)
          value = reverse value if  @isLittleEndian 
          fh.print( value)

          (1..7).each do |i|
            if  real>=0
              byte = int((real*256.0)+g_epsilon);
            else
              byte = int((real*256.0)-g_epsilon);
            end
            value = pack('C',byte)
            value = reverse value if  @isLittleEndian 
            fh.print( value)
            real = real * 256.0 - (byte + 0.0)
          end
        end
        
      elsif  recordDataType == ASCII_STRING   ## ascii string (null padded)
        
        fh.print( pack("a#{length}",data))
      end
    end
    $\=saveEnd
  end
  ################################################################################

  # == printRecord - prints a record just read
  # 
  #   usage:
  #     $gds2File -> printRecord(
  #                   -data => $record
  #                 );
  # 

  def printRecord (*arg)

    
    record = arg['-data']
    if  !  record 
      
      raise "printGds2Record expects a data record. Missing -data => \#{record} $!"
    end
    type = arg['-type']
    if   type 
      
      raise "printRecord does not take -type. Perhaps you meant to use printGds2Record? $!"
    end
    self.printGds2Record('-type'=>'record','-data'=>record)
  end
  ################################################################################

  ################################################################################

  # = Low Level Generic Read Methods
  # 

  ################################################################################

  # == readGds2Record - reads record header and data section
  # 
  #   usage:
  #   while ($gds2File -> readGds2Record)
  #   {
  #       if ($gds2File -> returnRecordTypeString eq 'LAYER')
  #       {
  #           $layersFound[$gds2File -> layer] = 1;
  #       }
  #   }
  # 

  def readGds2Record
    return "" if  @EOLIB 
    self.readGds2RecordHeader()
    self.readGds2RecordData()
    @INHEADER = FALSE
    @INDATA   = TRUE; ## actually just done w/ it
    @Record
  end
  ################################################################################

  # == readGds2RecordHeader - only reads gds2 record header section (2 bytes)
  # 
  #   slightly faster if you just want a certain thing...
  #   usage:
  #   while ($gds2File -> readGds2RecordHeader)
  #   {
  #       if ($gds2File -> returnRecordTypeString eq 'LAYER')
  #       {
  #           $gds2File -> readGds2RecordData;
  #           $layersFound[$gds2File -> returnLayer] = 1;
  #       }
  #   }
  # 

  def readGds2RecordHeader

    self.skipGds2RecordData() if  (! @INDATA) && (@INHEADER != UNKNOWN)  ; # need to read record data before header unless 1st time
    @Record = ''
    @RecordType = UNKNOWN
    @INHEADER = TRUE; ## will actually be just just done with it by the time we can check this ...
    @INDATA   = FALSE
    return '' if  @EOLIB ; ## no sense reading null padding..

    buffer = ''
    return 0 if  ! read(@FileHandle,buffer,4) 
    data
    #if (read($self -> {'FileHandle'},$data,2)) ### length
    data = substr(buffer,0,2)
    begin
      data = reverse data if  @isLittleEndian 
      @Record = data
      @Length = unpack 'S',data
      @BytesDone += @Length
    end

    #if (read($self -> {'FileHandle'},$data,1)) ## record type
    data = substr(buffer,2,1)
    begin
      data = reverse data if  @isLittleEndian 
      @Record += data
      @RecordType = unpack 'C',data
      @EOLIB = TRUE if  (@RecordType) == ENDLIB 

      if  @UsingPrettyPrint 
        
        putStrSpace('')   if  (@RecordType) == ENDSTR 
        putStrSpace('  ') if  (@RecordType) == BGNSTR 

        putElmSpace('  ') if  ((@RecordType) == TEXT) || ((@RecordType) == PATH) ||
                              ((@RecordType) == BOUNDARY) || ((@RecordType) == SREF) ||
                              ((@RecordType) == AREF) 
        if  (@RecordType) == ENDEL 
          
          putElmSpace('')
          @InTxt = FALSE
          @InBoundary = FALSE
        end
        @InTxt = TRUE if  (@RecordType) == TEXT 
        @InBoundary = TRUE if  (@RecordType) == BOUNDARY 
        if  ((@RecordType) == LIBNAME) || ((@RecordType) == STRNAME) 

          
          @DateFld = 0
        end
        @DateFld = 1 if  ((@RecordType) == BGNLIB) || ((@RecordType) == BGNSTR) 
      end
    end

    #if (read($self -> {'FileHandle'},$data,1)) ## data type
    data = substr(buffer,3,1)
    begin
      data = reverse data if  @isLittleEndian 
      @Record += data
      @DataType = unpack 'C',data
    end
    #printf("P:Length=%-5d RecordType=%-2d DataType=%-2d\n",$self -> {'Length'},$self -> {'RecordType'},$self -> {'DataType'}); ##DEBUG
    return 1
  end
  ################################################################################

  # == readGds2RecordData - only reads record data section
  # 
  #   slightly faster if you just want a certain thing...
  #   usage:
  #   while ($gds2File -> readGds2RecordHeader)
  #   {
  #       if ($gds2File -> returnRecordTypeString eq 'LAYER')
  #       {
  #           $gds2File -> readGds2RecordData;
  #           $layersFound[$gds2File -> returnLayer] = 1;
  #       }
  #   }
  # 

  def readGds2RecordData

    # self =shift

    self.readGds2RecordHeader() if  @INHEADER != TRUE ; # program did not read HEADER - needs to...
    return @Record if  @DataType == NO_REC_DATA ; # no sense going on...
    @INHEADER = FALSE; # not in HEADER - need to read HEADER next time around...
    @INDATA   = TRUE;  # rather in DATA - actually will be at the end of data by the time we test this...
    @RecordData = ''
    @RecordData = ()
    @CurrentDataList = ''
    bytesLeft= @Length - 4; ## 4 should have been just read by readGds2RecordHeader
    data
    if  @DataType == BIT_ARRAY      ## bit array
      
      @DataIndex=0
      read(@FileHandle,data,bytesLeft)
      data = reverse data if  @isLittleEndian 
      bitsLeft = bytesLeft * 8
      @Record += data
      @RecordData[0] = unpack "B#{bitsLeft}",data
      @CurrentDataList = (@RecordData[0])
      
    elsif  @DataType == INTEGER_2   ## 2 byte signed integer
      
      tmpListString = ''
      i = 0
      while  bytesLeft 
        
        read(@FileHandle,data,2)
        data = reverse data if  @isLittleEndian 
        @Record += data
        @RecordData[i] = unpack 's',data
        tmpListString += ','
        tmpListString+= @RecordData[i]
        i+=1
        bytesLeft -= 2
      end
      @DataIndex = i - 1
      @CurrentDataList = tmpListString
      
    elsif  @DataType == INTEGER_4   ## 4 byte signed integer
      
      tmpListString = ''
      i = 0
      buffer = ''
      read(@FileHandle,buffer,bytesLeft); ## try fewer reads
      0.step(bytesLeft, 4) do |start|
        data = substr(buffer,start,4)
        data = reverse data if  @isLittleEndian 
        @Record += data
        @RecordData[i] = unpack 'i',data
        tmpListString += ','
        tmpListString+= @RecordData[i]
        i+=1
      end
      @DataIndex = i - 1
      @CurrentDataList = tmpListString
      
    elsif  @DataType == REAL_4   ## 4 byte real
      
      raise "4-byte reals are not supported $!"
      
    elsif  @DataType == REAL_8   ## 8 byte real - UNITS, MAG, ANGLE
      
      resolution= @Resolution
      tmpListString = ''
      i = 0
      #(negative,exponent,mantdata,byteString,byte,mantissa,real)
      while  bytesLeft 
        
        read(@FileHandle,data,1); ## sign bit and 7 exponent bits
        @Record += data
        negative = unpack 'B',data; ## sign bit
        exponent = unpack 'C',data
        if  negative 
          
          exponent -= 192; ## 128 + 64
          
        else
          
          exponent -= 64
        end
        read(@FileHandle,data,7); ## mantissa bits
        mantdata = unpack 'b*',data
        @Record += data
        mantissa = 0.0
        (0..6).each do |j|
          byteString = substr(mantdata,0,8,'')
          byte = pack 'b*',byteString
          byte = unpack 'C',byte
          mantissa += byte / (256.0**(j+1))
        end
        real = mantissa * (16**exponent)
        real = (0 - real) if  negative 
        if  recordtypestrings[@RecordType] == 'UNITS' 
          
          if  @UUnits == -1.0 
            
            @UUnits = real
            
          elsif  @DBUnits == -1.0 
            
            @DBUnits = real
          end
          
        else
          
          ### this works because UUnits and DBUnits are 1st reals in GDS2 file
          real= int((real+(@UUnits/resolution))/@UUnits)*@UUnits if  @UUnits != 0 ; ## "rounds" off
        end
        @RecordData[i] = real
        tmpListString += ','
        tmpListString += @RecordData[i]
        i+=1
        bytesLeft -= 8
      end
      @DataIndex = i - 1
      @CurrentDataList = tmpListString
      
    elsif  @DataType == ASCII_STRING   ## ascii string (null padded)
      
      @DataIndex = 0
      read(@FileHandle,data,bytesLeft)
      @Record += data
      @RecordData[0] = unpack "a#{bytesLeft}",data
      @RecordData[0].gsub!(/\0/, ''); ## take off ending nulls
      @CurrentDataList = (@RecordData[0])
    end
    return 1
  end
  ################################################################################

  # = Low Level Generic Evaluation Methods
  # 

  ################################################################################

  # == returnRecordType - returns current (read) record type as integer
  # 
  #   usage:
  #   if ($gds2File -> returnRecordType == 6)
  #   {
  #       print "found STRNAME";
  #   }
  # 

  def returnRecordType

    # self =shift
    @RecordType
  end
  ################################################################################

  # == returnRecordTypeString - returns current (read) record type as string
  # 
  #   usage:
  #   if ($gds2File -> returnRecordTypeString eq 'LAYER')
  #   {
  #       code goes here...
  #   }
  # 

  def returnRecordTypeString

    # self =shift
    recordtypestrings[(@RecordType)]
  end
  ################################################################################

  # == returnRecordAsString - returns current (read) record as a string
  # 
  #   usage:
  #   while ($gds2File -> readGds2Record)
  #   {
  #       print $gds2File -> returnRecordAsString(-compact=>1);
  #   }
  # 

  def returnRecordAsString

    (*arg) = @_
    compact = arg['-compact']
    compact = FALSE if  !  compact 
    string = ''
    @UsingPrettyPrint = TRUE
    inText= @InTxt
    inBoundary= @InBoundary
    dateFld= @DateFld
    if  ! compact 
      
      string += getStrSpace() if  @RecordType != BGNSTR 
      string += getElmSpace() if  !(
          (@RecordType == BOUNDARY) ||
          (@RecordType == PATH) ||
          (@RecordType == TEXT) ||
          (@RecordType == SREF) ||
          (@RecordType == AREF)
        ) 
    end
    recordType = recordtypestrings[@RecordType]
    if  compact 
      
      string += compactrecordtypestrings[@RecordType]
      
    else
      
      string += recordType
    end
    i = 0
    while  i<= @DataIndex 
      
      if  @DataType == BIT_ARRAY 
        
        bitString= @RecordData[i]
        if  @isLittleEndian 
          
          bitString =~ %r|(........)(........)|
          bitString = "#{$2}#{$1}"
        end
        if  compact 
          
          string += ' fx' if bitString =~ /^1/ 
          if  inText && (@RecordType != STRANS) 
            
            string += ' f'
            string += '0' if  bitString =~ /00....$/ 
            string += '1' if  bitString =~ /01....$/ 
            string += '2' if  bitString =~ /10....$/ 
            string += '3' if  bitString =~ /11....$/ 
            string += ' t' if  bitString =~ /00..$/ 
            string += ' m' if  bitString =~ /01..$/ 
            string += ' b' if  bitString =~ /10..$/ 
            string += 'l' if  bitString =~ /00$/ 
            string += 'c' if  bitString =~ /01$/ 
            string += 'r' if  bitString =~ /10$/ 
          end
          
        else
          
          string += '  '+bitString
        end
        
      elsif  @DataType == INTEGER_2 
        
        if  compact 
          
          if  dateFld 
            
            num= @RecordData[i]
            if  dateFld =~ /^[17]$/ 
              
              if  dateFld == '1' 
                
                if  recordType == 'BGNLIB' 
                  
                  string += 'm='
                  
                else
                  
                  string += 'c='
                end
                
              elsif  dateFld == '7' 
                
                if  recordType == 'BGNLIB' 
                  
                  string += ' a='
                  
                else
                  
                  string += ' m='
                end
              end
              num += 1900 if  num < 1900 
            end
            num = sprintf("%02d",num)
            string += '-' if  dateFld =~ /^[2389]/ 
            string += ':' if  dateFld =~ /^[56]/ 
            string += ':' if  dateFld =~ /^1[12]/ 
            string += ' ' if  (dateFld == '4') || (dateFld == '10') 
            string += num
            
          else
            
            string += ' ' unless  string =~ / (a|m|pt|dt|tt)$/i 
            string+= @RecordData[i]
          end
          
        else
          
          string += '  '
          string+= @RecordData[i]
        end
        if  recordType == 'UNITS' 
          
          string.sub!(/(\d)\.e/, '$1e'); ## perl on Cygwin prints "1.e-9" others "1e-9"
          string.sub!(/(\d)e\-0+/, '$1e-'); ## different perls print 1e-9 1e-09 1e-009 etc... standardize to 1e-9
        end
        
      elsif  @DataType == INTEGER_4 
        
        if  compact 
          
          string += ' ' if  i 
          
        else
          
          string += '  '
        end
        string += cleanFloatNum(@RecordData[i]*(@UUnits))
        if  compact && i && (i == @RecordData.size) 
          
          string.sub!(/ +[\d\.\-]+ +[\d\.\-]+$/, '') if  inBoundary ; #remove last point
          string += ')'
        end
        
      elsif  @DataType == REAL_8 
        
        if  compact 
          
          string += ' ' unless  string =~ / (a|m|pt|dt|tt)$/i 
          
        else
          
          string += '  '
        end
        num= @RecordData[i]
        if  num =~ /e/i 
          
          num = cleanExpNum(num)
          
        else
          
          num = cleanFloatNum(num)
        end
        string += num
        if  recordType == 'UNITS' 
          
          string.sub!(/(\d)\.e/, '$1e'); ## perl on Cygwin prints "1.e-9" others "1e-9"
          string.sub!(/(\d)e\-0+/, '$1e-'); ## different perls print 1e-9 1e-09 1e-009 etc... standardize to shorter 1e-9
        end
        
      elsif  @DataType == ASCII_STRING 
        
        string += ' ' if  ! compact 
        string+= " '"+@RecordData[i]+"'"
      end
      i+=1
      dateFld+=1 if  dateFld 
    end

    if  compact 
      
      g_gdtstring += string
      if  (g_gdtstring =~ /}$/ || g_gdtstring =~ /^(gds2|lib|m).*\d$/) || (g_gdtstring =~ /^cell.*'$/) 
        
        string = "#{g_gdtstring}\n"
        string.sub!(/{ /, '{'); #a little more compact
        string.gsub!(/(dt0|pt0|tt0|m1|w0|f0) /, ''); #these are all default in true GDT format
        g_gdtstring = ""
        
      else
        
        string = ""
      end
    end

    string
  end
  ################################################################################

  # == returnXyAsArray - returns current (read) XY record as an array
  # 
  #   usage:
  #     $gds2File -> returnXyAsArray(
  #                     -asInteger => 0|1    ## (optional) default is true. Return integer
  #                                          ## array or if false return array of reals.
  #                     -withClosure => 0|1  ## (optional) default is true. Whether to
  #                                          ##return a rectangle with 5 or 4 points.
  #                );
  # 
  #   example:
  #   while ($gds2File -> readGds2Record)
  #   {
  #       my @xy = $gds2File -> returnXyAsArray if ($gds2File -> isXy);
  #   }
  # 

  def returnXyAsArray

    (*arg) = @_
    asInteger = arg['-asInteger']
    asInteger = TRUE unless   asInteger 
    withClosure = arg['-withClosure']
    withClosure = TRUE unless   withClosure 
    xys=[]
    if  self.isXy 
      
      i = 0
      stopPoint= @DataIndex
      if  withClosure 
        
        return @@RecordData if  asInteger 
        
      else
        
        stopPoint -= 2
      end
      num=0
      while  i <= stopPoint 
        
        if  asInteger 
          
          num= @RecordData[i]
          
        else
          
          num = cleanFloatNum(@RecordData[i]*(@UUnits))
        end
        push xys,num
        i+=1
      end
    end
    xys
  end
  ################################################################################


  # == returnRecordAsPerl - returns current (read) record as a perl command to facilitate the creation of parameterized gds2 data with perl.
  # 
  #   usage:
  #   #!/usr/local/bin/perl
  #   use GDS2;
  #   my $gds2File = new GDS2(-fileName=>"test.gds");
  #   while ($gds2File -> readGds2Record)
  #   {
  #       print $gds2File -> returnRecordAsPerl;
  #   }
  # 

  def returnRecordAsPerl

    (*arg) = @_

    gds2File = arg['-gds2File']
    gds2File = '$gds2File' unless   gds2File 

    pgr = arg['-printGds2Record']
    pgr = 'printGds2Record' unless   pgr 

    string = ''
    @UsingPrettyPrint = TRUE
    string += getStrSpace() if  @RecordType != BGNSTR 
    string += getElmSpace() if  !(
        (@RecordType == TEXT) ||
        (@RecordType == PATH) ||
        (@RecordType == BOUNDARY) ||
        (@RecordType == SREF) ||
        (@RecordType == AREF)
      ) 
    if  
      (@RecordType == TEXT) ||
        (@RecordType == PATH) ||
        (@RecordType == BOUNDARY) ||
        (@RecordType == SREF) ||
        (@RecordType == AREF) ||
        (@RecordType == ENDEL) ||
        (@RecordType == ENDSTR) ||
        (@RecordType == ENDLIB)
      
      
      string += gds2File+'->'+pgr+'(-type=>'+"'"+recordtypestrings[@RecordType]+"'"+');'
      
    else
      
      string += gds2File+'->'+pgr+'(-type=>'+"'"+recordtypestrings[@RecordType]+"',-data=>"
      i = 0
      maxi= @DataIndex
      if  maxi >= 1
        string += '['
      end
      while  i <= maxi 
        
        if  @DataType == BIT_ARRAY 
          
          bitString= @RecordData[i]
          if  @isLittleEndian 
            
            bitString =~ %r|(........)(........)|
            bitString = "#{$2}#{$1}"
          end
          string += "'#{bitString}'"
          
        elsif  @DataType == INTEGER_2 
          
          string += @RecordData[i]
          
        elsif  @DataType == INTEGER_4 
          
          string += @RecordData[i]
          
        elsif  @DataType == REAL_8 
          
          string += @RecordData[i]
          
        elsif  @DataType == ASCII_STRING 
          
          string += "'"+@RecordData[i]+"'"
        end
        if  i < maxi
          string += ', '
        end
        i+=1
      end
      if  maxi >= 1
        string += ']'
      end
      string += ');'
    end
    string
  end
  ################################################################################


  # = Low Level Specific Write Methods
  # 

  ################################################################################

  # == printAngle - prints ANGLE record
  # 
  #   usage:
  #     $gds2File -> printAngle(-num=>#.#);
  # 

  def printAngle (*arg)

    
    angle = arg['-num']
    if   angle 
      
      angle=posAngle(angle)
      
    else
      
      angle = -1; #not really... just means not specified
    end
    self.printGds2Record('-type' => 'ANGLE','-data' => angle) if  angle >= 0 
  end
  ################################################################################

  # == printAttrtable - prints ATTRTABLE record
  # 
  #   usage:
  #     $gds2File -> printAttrtable(-string=>$string);
  # 

  def printAttrtable (*arg)

    
    string = arg['-string']
    unless   string 
      
      raise "printAttrtable expects a string. Missing -string => 'text' $!"
    end
    self.printGds2Record('-type' => 'ATTRTABLE','-data' => string)
  end
  ################################################################################

  # == printBgnextn - prints BGNEXTN record
  # 
  #   usage:
  #     $gds2File -> printBgnextn(-num=>#.#);
  # 

  def printBgnextn (*arg)

    
    num = arg['-num']
    unless   num 
      
      raise "printBgnextn expects a extension number. Missing -num => #.# $!"
    end
    resolution= @Resolution
    if  num >= 0
      num = int((num*resolution)+g_epsilon);
    else
      num = int((num*resolution)-g_epsilon);end
    self.printGds2Record('-type' => 'BGNEXTN','-data' => num)
  end
  ################################################################################

  # == printBgnlib - prints BGNLIB record
  # 
  #   usage:
  #     $gds2File -> printBgnlib(
  #                             -isoDate => 0|1 ## (optional) use ISO 4 digit date 2001 vs 101
  #                            );
  # 

  def printBgnlib (isoDate = false, *arg)
    (sec,min,hour,mday,mon,year,wday,yday,isdst) = localtime(time)
    mon+=1
    year += 1900 if  isoDate ; ## Cadence likes year left "as is". GDS format supports year number up to 65535 -- 101 vs 2001
    self.printGds2Record('-type'=>'BGNLIB','-data'=>[year,mon,mday,hour,min,sec,year,mon,mday,hour,min,sec])
  end
  ################################################################################

  # == printBox - prints BOX record
  # 
  #   usage:
  #     $gds2File -> printBox;
  # 

  def printBox

    # self =shift
    self.printGds2Record('-type' => 'BOX')
  end
  ################################################################################

  # == printBoxtype - prints BOXTYPE record
  # 
  #   usage:
  #     $gds2File -> printBoxtype(-num=>#);
  # 

  def printBoxtype (*arg)

    
    num = arg['-num']
    unless   num 
      
      raise "printBoxtype expects a number. Missing -num => # $!"
    end
    self.printGds2Record('-type' => 'BOXTYPE','-data' => num)
  end
  ################################################################################

  # == printColrow - prints COLROW record
  # 
  #   usage:
  #     $gds2File -> printBoxtype(-columns=>#, -rows=>#);
  # 

  def printColrow (*arg)

    
    columns = arg['-columns']
    if  (!  columns)||(columns <= 0) 
      
      columns=1
      
    else
      
      columns=int(columns)
    end
    rows = arg['-rows']
    if  (!  rows)||(rows <= 0) 
      
      rows=1
      
    else
      
      rows=int(rows)
    end
    self.printGds2Record('-type' => 'COLROW','-data' => [columns,rows])
  end
  ################################################################################

  # == printDatatype - prints DATATYPE record
  # 
  #   usage:
  #     $gds2File -> printDatatype(-num=>#);
  # 

  def printDatatype (*arg)

    
    dataType = arg['-num']
    dataType=0 unless   dataType 
    self.printGds2Record('-type' => 'DATATYPE','-data' => dataType)
  end
  ################################################################################

  def printEflags

    # self =shift
    raise "EFLAGS type not supported $!"
  end
  ################################################################################

  # == printElkey - prints ELKEY record
  # 
  #   usage:
  #     $gds2File -> printElkey(-num=>#);
  # 

  def printElkey (*arg)

    
    num = arg['-num']
    unless   num 
      
      raise "printElkey expects a number. Missing -num => #.# $!"
    end
    self.printGds2Record('-type' => 'ELKEY','-data' => num)
  end
  ################################################################################

  # == printEndel - closes an element definition
  # 

  def printEndel

    # self =shift
    self.printGds2Record('-type' => 'ENDEL')
  end
  ################################################################################

  # == printEndextn - prints path end extension record
  # 
  #   usage:
  #     $gds2File printEndextn -> (-num=>#.#);
  # 

  def printEndextn (*arg)

    
    num = arg['-num']
    unless   num 
      
      raise "printEndextn expects a extension number. Missing -num => #.# $!"
    end
    resolution= @Resolution
    if  num >= 0
      num = int((num*resolution)+g_epsilon);
    else
      num = int((num*resolution)-g_epsilon);end
    self.printGds2Record('-type' => 'ENDEXTN','-data' => num)
  end
  ################################################################################

  # == printEndlib - closes a library definition
  # 

  def printEndlib

    # self =shift
    self.printGds2Record('-type' => 'ENDLIB')
  end
  ################################################################################

  # == printEndstr - closes a structure definition
  # 

  def printEndstr

    # self =shift
    self.printGds2Record('-type' => 'ENDSTR')
  end
  ################################################################################

  # == printEndmasks - prints a ENDMASKS
  # 

  def printEndmasks

    # self =shift
    self.printGds2Record('-type' => 'ENDMASKS')
  end
  ################################################################################

  # == printFonts - prints a FONTS record
  # 
  #   usage:
  #     $gds2File -> printFonts(-string=>'names_of_font_files');
  # 

  def printFonts (*arg)

    
    string = arg['-string']
    unless   string 
      
      raise "printFonts expects a string. Missing -string => 'text' $!"
    end
    self.printGds2Record('-type' => 'FONTS','-data' => string)
  end
  ################################################################################

  def printFormat (*arg)

    
    num = arg['-num']
    unless   num 
      
      raise "printFormat expects a number. Missing -num => #.# $!"
    end
    self.printGds2Record('-type' => 'FORMAT','-data' => num)
  end
  ################################################################################

  def printGenerations

    # self =shift
    self.printGds2Record('-type' => 'GENERATIONS')
  end
  ################################################################################

  # == printHeader - Prints a rev 3 header
  # 
  #   usage:
  #     $gds2File -> printHeader(
  #                   -num => #  ## optional, defaults to 3. valid revs are 0,3,4,5,and 600
  #                 );
  # 

  def printHeader (*arg)

    
    rev = arg['-num']
    unless   rev 
      
      rev=3
    end
    self.printGds2Record('-type'=>'HEADER','-data'=>rev)
  end
  ################################################################################

  # == printLayer - prints a LAYER number
  # 
  #   usage:
  #     $gds2File -> printLayer(
  #                   -num => #  ## optional, defaults to 0.
  #                 );
  # 

  def printLayer (*arg)

    
    layer = arg['-num']
    layer = 0 unless   layer 
    self.printGds2Record('-type' => 'LAYER','-data' => layer)
  end
  ################################################################################

  def printLibdirsize

    # self =shift
    self.printGds2Record('-type' => 'LIBDIRSIZE')
  end
  ################################################################################

  # == printLibname - Prints library name
  # 
  #   usage:
  #     printLibname(-name=>$name);
  # 

  def printLibname (*arg)

    
    libName = arg['-name']
    unless   libName 
      
      raise "printLibname expects a library name. Missing -name => 'name' $!"
    end
    self.printGds2Record('-type' => 'LIBNAME','-data' => libName)
  end
  ################################################################################

  def printLibsecur

    # self =shift
    self.printGds2Record('-type' => 'LIBSECUR')
  end
  ################################################################################

  def printLinkkeys (*arg)

    
    num = arg['-num']
    unless   num 
      
      raise "printLinkkeys expects a number. Missing -num => #.# $!"
    end
    self.printGds2Record('-type' => 'LINKKEYS','-data' => num)
  end
  ################################################################################

  def printLinktype (*arg)

    
    num = arg['-num']
    unless   num 
      
      raise "printLinktype expects a number. Missing -num => #.# $!"
    end
    self.printGds2Record('-type' => 'LINKTYPE','-data' => num)
  end
  ################################################################################

  # == printPathtype - prints a PATHTYPE number
  # 
  #   usage:
  #     $gds2File -> printPathtype(
  #                   -num => #  ## optional, defaults to 0.
  #                 );
  # 

  def printPathtype (*arg)

    
    pathType = arg['-num']
    pathType=0 if  !  pathType 
    self.printGds2Record('-type' => 'PATHTYPE','-data' => pathType) if  pathType 
  end
  ################################################################################

  # == printMag - prints a MAG number
  # 
  #   usage:
  #     $gds2File -> printMag(
  #                   -num => #.#  ## optional, defaults to 0.0
  #                 );
  # 

  def printMag (*arg)

    
    mag = arg['-num']
    mag=0 if  (!  mag)||(mag <= 0) 
    mag = cleanFloatNum(mag)
    self.printGds2Record('-type' => 'MAG','-data' => mag) if  mag 
  end
  ################################################################################

  def printMask (*arg)

    
    string = arg['-string']
    unless   string 
      
      raise "printMask expects a string. Missing -string => 'text' $!"
    end
    self.printGds2Record('-type' => 'MASK','-data' => string)
  end
  ################################################################################

  def printNode

    # self =shift
    self.printGds2Record('-type' => 'NODE')
  end
  ################################################################################

  # == printNodetype - prints a NODETYPE number
  # 
  #   usage:
  #     $gds2File -> printNodetype(
  #                   -num => #
  #                 );
  # 

  def printNodetype (*arg)

    
    num = arg['-num']
    unless   num 
      
      raise "printNodetype expects a number. Missing -num => # $!"
    end
    self.printGds2Record('-type' => 'NODETYPE','-data' => num)
  end
  ################################################################################

  def printPlex (*arg)

    
    num = arg['-num']
    unless   num 
      
      raise "printPlex expects a number. Missing -num => #.# $!"
    end
    self.printGds2Record('-type' => 'PLEX','-data' => num)
  end
  ################################################################################

  # == printPresentation - prints a text presentation record
  # 
  #   usage:
  #     $gds2File -> printPresentation(
  #                   -font => #,  ##optional, defaults to 0, valid numbers are 0-3
  #                   -top, ||-middle, || -bottom, ## vertical justification
  #                   -left, ||-center, || -right, ## horizontal justification
  #                 );
  # 
  #   example:
  #     gds2File -> printPresentation(-font=>0,-top,-left);
  # 

  def printPresentation (*arg)

    
    font = arg['-font']
    if  (!  font) || (font < 0) || (font > 3) 
      
      font=0
    end
    font = sprintf("%02d",font)

    vertical
    top = arg['-top']
    middle = arg['-middle']
    bottom = arg['-bottom']
    if      top    ; vertical = '00';
    elsif   bottom ; vertical = '10';
    else           ; vertical = '01';end ## middle
    horizontal
    left   = arg['-left']
    center = arg['-center']
    right  = arg['-right']
    if      left   horizontal = '00';
    elsif   right  horizontal = '10';
    else                   horizontal = '01';end ## center

    bitstring = '0'*10
    bitstring += "#{font}#{vertical}#{horizontal}"
    self.printGds2Record('-type' => 'PRESENTATION','-data' => bitstring)
  end
  ################################################################################

  # == printPropattr - prints a property id number
  # 
  #   usage:
  #     $gds2File -> printPropattr( -num => # );
  # 

  def printPropattr (*arg)

    
    num = arg['-num']
    unless   num 
      
      raise "printPropattr expects a number. Missing -num => # $!"
    end
    self.printGds2Record('-type' => 'PROPATTR','-data' => num)
  end
  ################################################################################

  # == printPropvalue - prints a property value string
  # 
  #   usage:
  #     $gds2File -> printPropvalue( -string => $string );
  # 

  def printPropvalue (*arg)

    
    string = arg['-string']
    unless   string 
      
      raise "printPropvalue expects a string. Missing -string => 'text' $!"
    end
    self.printGds2Record('-type' => 'PROPVALUE','-data' => string)
  end
  ################################################################################

  def printReflibs (*arg)

    
    string = arg['-string']
    unless   string 
      
      raise "printReflibs expects a string. Missing -string => 'text' $!"
    end
    self.printGds2Record('-type' => 'REFLIBS','-data' => string)
  end
  ################################################################################

  def printReserved (*arg)

    
    num = arg['-num']
    unless   num 
      
      raise "printReserved expects a number. Missing -num => #.# $!"
    end
    self.printGds2Record('-type' => 'RESERVED','-data' => num)
  end
  ################################################################################

  # == printSname - prints a SNAME string
  # 
  #   usage:
  #     $gds2File -> printSname( -name => $cellName );
  # 

  def printSname (*arg)

    
    string = arg['-name']
    if  !  string 
      
      raise "printSname expects a cell name. Missing -name => 'text' $!"
    end
    self.printGds2Record('-type' => 'SNAME','-data' => string)
  end
  ################################################################################

  def printSpacing

    # self =shift
    raise "SPACING type not supported $!"
  end
  ################################################################################

  def printSrfname

    # self =shift
    self.printGds2Record('-type' => 'SRFNAME')
  end
  ################################################################################

  # == printStrans - prints a STRANS record
  # 
  #   usage:
  #     $gds2File -> printStrans( -reflect );
  # 

  def printStrans (*arg)

    
    reflect = arg['-reflect']
    if  (!  reflect)||(reflect <= 0) 
      
      reflect = 0
      
    else
      
      reflect = 1
    end
    data = reflect+'0'*15; ## 16 'bit' string
    self.printGds2Record('-type' => 'STRANS','-data' => data)
  end
  ################################################################################

  def printStrclass

    # self =shift
    self.printGds2Record('-type' => 'STRCLASS')
  end
  ################################################################################

  # == printString - prints a STRING record
  # 
  #   usage:
  #     $gds2File -> printSname( -string => $text );
  # 

  def printString (*arg)

    
    string = arg['-string']
    unless   string 
      
      raise "printString expects a string. Missing -string => 'text' $!"
    end
    self.printGds2Record('-type' => 'STRING','-data' => string)
  end
  ################################################################################

  # == printStrname - prints a structure name string
  # 
  #   usage:
  #     $gds2File -> printStrname( -name => $cellName );
  # 

  def printStrname (*arg)

    
    strName = arg['-name']
    unless   strName 
      
      raise "printStrname expects a structure name. Missing -name => 'name' $!"
    end
    self.printGds2Record('-type' => 'STRNAME','-data' => strName)
  end
  ################################################################################

  def printStrtype

    # self =shift
    raise "STRTYPE type not supported $!"
  end
  ################################################################################

  def printStyptable (*arg)

    
    string = arg['-string']
    unless   string 
      
      raise "printStyptable expects a string. Missing -string => 'text' $!"
    end
    self.printGds2Record('-type' => 'STYPTABLE','-data' => string)
  end
  ################################################################################

  def printTapecode (*arg)

    
    num = arg['-num']
    unless   num 
      
      raise "printTapecode expects a number. Missing -num => #.# $!"
    end
    self.printGds2Record('-type' => 'TAPECODE','-data' => num)
  end
  ################################################################################

  def printTapenum (*arg)

    
    num = arg['-num']
    unless   num 
      
      raise "printTapenum expects a number. Missing -num => #.# $!"
    end
    self.printGds2Record('-type' => 'TAPENUM','-data' => num)
  end
  ################################################################################

  def printTextnode

    # self =shift
    self.printGds2Record('-type' => 'TEXTNODE')
  end
  ################################################################################

  # == printTexttype - prints a text type number
  # 
  #   usage:
  #     $gds2File -> printTexttype( -num => # );
  # 

  def printTexttype (*arg)

    
    num = arg['-num']
    unless   num 
      
      raise "printTexttype expects a number. Missing -num => # $!"
    end
    num = 0 if  num < 0 
    self.printGds2Record('-type' => 'TEXTTYPE','-data' => num)
  end
  ################################################################################

  def printUinteger

    # self =shift
    raise "UINTEGER type not supported $!"
  end
  ################################################################################

  # == printUnits - Prints units record.
  # 
  #   options:
  #     -uUnit   => real number ## (optional) default is 0.001
  #     -dbUnit  => real number ## (optional) default is 1e-9
  # 

  def printUnits (*arg)

    

    uUnit = arg['-uUnit']
    if  !  uUnit 
      
      uUnit = 0.001
      
    else
      
      @Resolution = (1 / uUnit); ## default is 1000 - already set in new()
    end
    @UUnits = uUnit
    #################################################
    dbUnit = arg['-dbUnit']
    unless   dbUnit 
      
      dbUnit = 1e-9
    end
    @DBUnits = dbUnit
    #################################################

    self.printGds2Record('-type' => 'UNITS','-data' => [uUnit,dbUnit])
  end
  ################################################################################

  def printUstring

    # self =shift
    raise "USTRING type not supported $!"
  end
  ################################################################################

  # == printWidth - prints a width number
  # 
  #   usage:
  #     $gds2File -> printWidth( -num => # );
  # 

  def printWidth (*arg)

    
    width = arg['-num']
    if  (!  width)||(width <= 0) 
      
      width=0
    end
    self.printGds2Record('-type' => 'WIDTH','-data' => width) if  width 
  end
  ################################################################################

  # == printXy - prints an XY array
  # 
  #   usage:
  #     $gds2File -> printXy( -xyInt => \@arrayGds2Ints );
  #     -or-
  #     $gds2File -> printXy( -xy => \@arrayReals );
  # 
  #     -xyInt most useful if reading and modifying... -xy if creating from scratch
  # 

  def printXy (*arg)

    
    #### -xyInt most useful if reading and modifying... -xy if creating from scratch
    xyInt = arg['-xyInt']; ## $xyInt should be a reference to an array of internal GDS2 format integers
    xy = arg['-xy']; ## $xy should be a reference to an array of reals
    resolution= @Resolution
    if  ! (( xy) || ( xyInt)) 
      
      raise "printXy expects an xy array reference. Missing -xy => \\\#{array} $!"
    end
    if   xyInt 
      
      xy = xyInt
      resolution = 1
    end
    xyTmp=[]; ##don't pollute array passed in
    xy.each do |xyi| ## e.g. 3.4 in -> 3400 out
      
      if  xyi >= 0
        xyTmp << int(((xyi)*resolution)+g_epsilon);
      else
        xyTmp << int(((xyi)*resolution)-g_epsilon);end
    end
    self.printGds2Record('-type' => 'XY','-data' => xyTmp)
  end
  ################################################################################


  # = Low Level Specific Evaluation Methods
  # 

  # == returnFilePosition - return current byte position (NOT zero based)
  # 
  #   usage:
  #     my $position = $gds2File -> returnFilePosition;
  # 

  def returnFilePosition
    @BytesDone
  end
  ################################################################################

  def tellSize ## old name
    @BytesDone
  end
  ################################################################################


  # == returnBgnextn - returns bgnextn if record is BGNEXTN else returns 0
  # 
  #   usage:
  # 

  def returnBgnextn
    ## 2 byte signed integer
    if  self.isBgnextn   @RecordData[0]; 
    else  0; end
  end
  ################################################################################

  # == returnDatatype - returns datatype # if record is DATATYPE else returns -1
  # 
  #   usage:
  #     $dataTypesFound[$gds2File -> returnDatatype] = 1;
  # 

  def returnDatatype

    # self =shift
    ## 2 byte signed integer
    if  self.isDatatype   @RecordData[0]; 
    else  UNKNOWN; end
  end
  ################################################################################

  # == returnEndextn- returns endextn if record is ENDEXTN else returns 0
  # 
  #   usage:
  # 

  def returnEndextn
    ## 2 byte signed integer
    if  self.isEndextn   @RecordData[0]; 
    else  0; end
  end
  ################################################################################


  # == returnLayer - returns layer # if record is LAYER else returns -1
  # 
  #   usage:
  #     $layersFound[$gds2File -> returnLayer] = 1;
  # 

  def returnLayer
    ## 2 byte signed integer
    if  self.isLayer   @RecordData[0]; 
    else  UNKNOWN; end
  end
  ################################################################################

  # == returnPathtype - returns pathtype # if record is PATHTYPE else returns -1
  # 
  #   usage:
  # 

  def returnPathtype
    ## 2 byte signed integer
    return @RecordData[0] if  self.isPathtype
    return  UNKNOWN
  end
  ################################################################################

  # == returnPropattr - returns propattr # if record is PROPATTR else returns -1
  # 
  #   usage:
  # 

  def returnPropattr
    ## 2 byte signed integer
    return @RecordData[0] if self.isPropattr
    return UNKNOWN
  end
  ################################################################################

  # == returnPropvalue - returns propvalue string if record is PROPVALUE else returns ''
  # 
  #   usage:
  # 

  def returnPropvalue
    return @RecordData[0] if self.isPropvalue 
    return  ''
  end
  ################################################################################

  # == returnSname - return string if record type is SNAME else ''
  # 

  def returnSname

    # self =shift
    if  self.isSname
      @RecordData[0]; 
    else  ''; end
  end
  ################################################################################

  # == returnString - return string if record type is STRING else ''
  # 

  def returnString
    if  self.isString
      @RecordData[0]; 
    else  ''; end
  end
  ################################################################################

  # == returnStrname - return string if record type is STRNAME else ''
  # 

  def returnStrname

    # self =shift
    if  self.isStrname
      @RecordData[0]; 
    else  ''; end
  end
  ################################################################################

  # == returnTexttype - returns texttype # if record is TEXTTYPE else returns -1
  # 
  #   usage:
  #     $TextTypesFound[$gds2File -> returnTexttype] = 1;
  # 

  def returnTexttype

    # self =shift
    ## 2 byte signed integer
    if  self.isTexttype
      @RecordData[0]; 
    else  UNKNOWN; end
  end
  ################################################################################

  # == returnWidth - returns width # if record is WIDTH else returns -1
  # 
  #   usage:
  # 

  def returnWidth

    # self =shift
    ## 4 byte signed integer
    if  self.isWidth
      @RecordData[0]; 
    else  UNKNOWN; end
  end
  ################################################################################

  ################################################################################

  # = Low Level Specific Boolean Methods
  # 

  ################################################################################

  # == isAref - return 0 or 1 depending on whether current record is an aref
  def isAref
    return  @RecordType == AREF
  end
  ################################################################################

  # == isBgnlib - return 0 or 1 depending on whether current record is a bgnlib
  # 

  def isBgnlib
    return  @RecordType == BGNLIB
  end
  ################################################################################

  # == isBgnstr - return 0 or 1 depending on whether current record is a bgnstr
  # 

  def isBgnstr
    return  @RecordType == BGNSTR
  end
  ################################################################################

  # == isBoundary - return 0 or 1 depending on whether current record is a boundary
  # 

  def isBoundary
    return  @RecordType == BOUNDARY
  end
  ################################################################################

  # == isDatatype - return 0 or 1 depending on whether current record is datatype
  # 

  def isDatatype
    return @RecordType == DATATYPE
  end
  ################################################################################

  # == isEndlib - return 0 or 1 depending on whether current record is endlib
  # 

  def isEndlib
    return @RecordType == ENDLIB
  end
  ################################################################################

  # == isEndel - return 0 or 1 depending on whether current record is endel
  # 

  def isEndel
    return @RecordType == ENDEL
  end
  ################################################################################

  # == isEndstr - return 0 or 1 depending on whether current record is endstr
  # 

  def isEndstr
    return @RecordType == ENDSTR
  end
  ################################################################################


  # == isHeader - return 0 or 1 depending on whether current record is a header
  # 

  def isHeader
    return @RecordType == HEADER
  end
  ################################################################################

  # == isLibname - return 0 or 1 depending on whether current record is a libname
  # 

  def isLibname
    return @RecordType == LIBNAME
  end
  ################################################################################

  # == isPath - return 0 or 1 depending on whether current record is a path
  # 

  def isPath
    return @RecordType == PATH
  end
  ################################################################################

  # == isSref - return 0 or 1 depending on whether current record is an sref
  # 

  def isSref
    return @RecordType == SREF
  end
  ################################################################################

  # == isSrfname - return 0 or 1 depending on whether current record is an srfname
  # 

  def isSrfname
    return @RecordType == SRFNAME
  end
  ################################################################################

  # == isText - return 0 or 1 depending on whether current record is a text
  # 

  def isText
    return @RecordType == TEXT
  end
  ################################################################################

  # == isUnits - return 0 or 1 depending on whether current record is units
  # 

  def isUnits
    return @RecordType == UNITS
  end
  ################################################################################

  # == isLayer - return 0 or 1 depending on whether current record is layer
  # 

  def isLayer
    return @RecordType == LAYER
  end
  ################################################################################

  # == isStrname - return 0 or 1 depending on whether current record is strname
  # 

  def isStrname
    return @RecordType == STRNAME
  end
  ################################################################################

  # == isWidth - return 0 or 1 depending on whether current record is width
  # 

  def isWidth
    return @RecordType == WIDTH
  end
  ################################################################################

  # == isXy - return 0 or 1 depending on whether current record is xy
  # 

  def isXy
    return @RecordType == XY
  end
  ################################################################################

  # == isSname - return 0 or 1 depending on whether current record is sname
  # 

  def isSname
    return @RecordType == SNAME
  end
  ################################################################################

  # == isColrow - return 0 or 1 depending on whether current record is colrow
  # 

  def isColrow
    return @RecordType == COLROW
  end
  ################################################################################

  # == isTextnode - return 0 or 1 depending on whether current record is a textnode
  # 

  def isTextnode
    return @RecordType == TEXTNODE
  end
  ################################################################################

  # == isNode - return 0 or 1 depending on whether current record is a node
  # 

  def isNode
    return @RecordType == NODE
  end
  ################################################################################

  # == isTexttype - return 0 or 1 depending on whether current record is a texttype
  # 

  def isTexttype
    return @RecordType == TEXTTYPE
  end
  ################################################################################

  # == isPresentation - return 0 or 1 depending on whether current record is a presentation
  # 

  def isPresentation
    return @RecordType == PRESENTATION
  end
  ################################################################################

  # == isSpacing - return 0 or 1 depending on whether current record is a spacing
  # 

  def isSpacing
    return @RecordType == SPACING
  end
  ################################################################################

  # == isString - return 0 or 1 depending on whether current record is a string
  # 

  def isString
    return @RecordType == STRING
  end
  ################################################################################

  # == isStrans - return 0 or 1 depending on whether current record is a strans
  # 

  def isStrans
    return @RecordType == STRANS
  end
  ################################################################################

  # == isMag - return 0 or 1 depending on whether current record is a mag
  # 

  def isMag
    return @RecordType == MAG
  end
  ################################################################################

  # == isAngle - return 0 or 1 depending on whether current record is a angle
  # 

  def isAngle
    return @RecordType == ANGLE
  end
  ################################################################################

  # == isUinteger - return 0 or 1 depending on whether current record is a uinteger
  # 

  def isUinteger
    return @RecordType == UINTEGER
  end
  ################################################################################

  # == isUstring - return 0 or 1 depending on whether current record is a ustring
  # 

  def isUstring
    return @RecordType == USTRING
  end
  ################################################################################

  # == isReflibs - return 0 or 1 depending on whether current record is a reflibs
  # 

  def isReflibs
    return @RecordType == REFLIBS
  end
  ################################################################################

  # == isFonts - return 0 or 1 depending on whether current record is a fonts
  # 

  def isFonts
    return @RecordType == FONTS
  end
  ################################################################################

  # == isPathtype - return 0 or 1 depending on whether current record is a pathtype
  # 

  def isPathtype
    return @RecordType == PATHTYPE
  end
  ################################################################################

  # == isGenerations - return 0 or 1 depending on whether current record is a generations
  # 

  def isGenerations
    return @RecordType == GENERATIONS
  end
  ################################################################################

  # == isAttrtable - return 0 or 1 depending on whether current record is a attrtable
  # 

  def isAttrtable
    return @RecordType == ATTRTABLE
  end
  ################################################################################

  # == isStyptable - return 0 or 1 depending on whether current record is a styptable
  # 

  def isStyptable
    return @RecordType == STYPTABLE
  end
  ################################################################################

  # == isStrtype - return 0 or 1 depending on whether current record is a strtype
  # 

  def isStrtype
    return @RecordType == STRTYPE
  end
  ################################################################################

  # == isEflags - return 0 or 1 depending on whether current record is a eflags
  # 

  def isEflags
    return @RecordType == EFLAGS
  end
  ################################################################################

  # == isElkey - return 0 or 1 depending on whether current record is a elkey
  # 

  def isElkey
    return @RecordType == ELKEY
  end
  ################################################################################

  # == isLinktype - return 0 or 1 depending on whether current record is a linktype
  # 

  def isLinktype
    return @RecordType == LINKTYPE
  end
  ################################################################################

  # == isLinkkeys - return 0 or 1 depending on whether current record is a linkkeys
  # 

  def isLinkkeys
    return @RecordType == LINKKEYS
  end
  ################################################################################

  # == isNodetype - return 0 or 1 depending on whether current record is a nodetype
  # 

  def isNodetype
    return @RecordType == NODETYPE
  end
  ################################################################################

  # == isPropattr - return 0 or 1 depending on whether current record is a propattr
  # 

  def isPropattr
    return @RecordType == PROPATTR
  end
  ################################################################################

  # == isPropvalue - return 0 or 1 depending on whether current record is a propvalue
  # 

  def isPropvalue
    return @RecordType == PROPVALUE
  end
  ################################################################################

  # == isBox - return 0 or 1 depending on whether current record is a box
  # 

  def isBox
    return @RecordType == BOX
  end
  ################################################################################

  # == isBoxtype - return 0 or 1 depending on whether current record is a boxtype
  # 

  def isBoxtype
    return @RecordType == BOXTYPE
  end
  ################################################################################

  # == isPlex - return 0 or 1 depending on whether current record is a plex
  # 

  def isPlex
    return @RecordType == PLEX
  end
  ################################################################################

  # == isBgnextn - return 0 or 1 depending on whether current record is a bgnextn
  # 

  def isBgnextn
    return @RecordType == BGNEXTN
  end
  ################################################################################

  # == isEndextn - return 0 or 1 depending on whether current record is a endextn
  # 

  def isEndextn
    return @RecordType == ENDEXTN
  end
  ################################################################################

  # == isTapenum - return 0 or 1 depending on whether current record is a tapenum
  # 

  def isTapenum
    return @RecordType == TAPENUM
  end
  ################################################################################

  # == isTapecode - return 0 or 1 depending on whether current record is a tapecode
  # 

  def isTapecode
    return @RecordType == TAPECODE
  end
  ################################################################################

  # == isStrclass - return 0 or 1 depending on whether current record is a strclass
  # 

  def isStrclass
    return @RecordType == STRCLASS
  end
  ################################################################################

  # == isReserved - return 0 or 1 depending on whether current record is a reserved
  # 

  def isReserved
    return @RecordType == RESERVED
  end
  ################################################################################

  # == isFormat - return 0 or 1 depending on whether current record is a format
  # 

  def isFormat
    return  @RecordType == FORMAT
  end
  ################################################################################

  # == isMask - return 0 or 1 depending on whether current record is a mask
  # 

  def isMask
    return  @RecordType == MASK
  end
  ################################################################################

  # == isEndmasks - return 0 or 1 depending on whether current record is a endmasks
  # 

  def isEndmasks
    return @RecordType == ENDMASKS
  end
  ################################################################################

  # == isLibdirsize - return 0 or 1 depending on whether current record is a libdirsize
  # 

  def isLibdirsize
    return @RecordType == LIBDIRSIZE
  end
  ################################################################################

  # == isLibsecur - return 0 or 1 depending on whether current record is a libsecur
  # 

  def isLibsecur
    return @RecordType == LIBSECUR
  end
  ################################################################################

  ################################################################################
  ## support functions

  def getRecordData
    dt = @DataType
    if  dt == NO_REC_DATA 
      return ''
    elsif  dt==INTEGER_2 || dt==INTEGER_4 || dt==REAL_8 
      return @CurrentDataList.sub!(/^,/, '').split(/,/)
    elsif dt == ASCII_STRING 
      return @CurrentDataList.sub!(/\0/, '')
    else ## bit_array
      return @CurrentDataList
    end
  end
  ################################################################################

  def readRecordTypeAndData

    return [recordtypestrings[@RecordType], @RecordData]
  end
  ################################################################################

  def skipGds2RecordData

    # self =shift
    self.readGds2RecordHeader() if  @INHEADER != TRUE ; ## safety - need to read HEADER if INHEADER == UNKNOWN or FALSE
    @INHEADER = FALSE
    @INDATA   = TRUE;  # in DATA - actually will be at the end of data by the time we test this...
    ## 4 should have been just read by readGds2RecordHeader
    seek(@FileHandle,@Length - 4,SEEK_CUR); ## seek seems to run a little faster than read
    @DataIndex = UNKNOWN
    return 1
  end
  ################################################################################

  ### return number of XY coords if XY record
  def returnNumCoords

    # self =shift
    if  @RecordType == XY   ## 4 byte signed integer
      
      int((@Length - 4) / 8)
      
    else
      
      0
    end
  end
  ################################################################################

  def roundNum(num,places)
    # self =shift
    sprintf("%.#{places}f",num)
  end
  ################################################################################

  def scaleNum (num,scale)
    raise "1st number passed into scaleNum() must be an integer $!" if  num !~ %r|^-?\d+| 
    num = num * scale
    num = int(num+0.5) if  num =~ %r|\.| 
    num
  end
  ################################################################################

  def snapNum (num,snap)

    raise "1st number passed into snapNum() must be an integer $!" if  num !~ %r|^-?\d+$| 
    snapLength = length("#{snap}")
    lean=1; ##init
    lean = -1 if num < 0 
    ## snap to grid..
    littlePart=substr(num,-snapLength,snapLength)
    if num<0 
      littlePart = -littlePart
    end
    littlePart = int((littlePart/snap)+(0.5*lean))*snap
    bigPart=substr(num,0,-snapLength)
    if  bigPart =~ %r|^[-]?$| 
      
      bigPart=0
      
    else
      
      bigPart *= 10**snapLength
    end
    num = bigPart + littlePart
    num
  end
  ################################################################################

  ################################################################################
  ## some vendor tools have trouble w/ negative angles and angles >= 360
  ## so we normalize to positive equivalent
  ################################################################################
  def posAngle(angle)
    angle += 360.0 while  angle < 0.0 
    angle -= 360.0 while  angle >= 360.0 
    angle = cleanFloatNum(angle)
    angle
  end
  ################################################################################

  # == recordSize - return current record size
  # 
  #   usage:
  #     my $len = $gds2File -> recordSize;
  # 
  # 

  def recordSize
    @Length
  end
  ################################################################################

  # == dataSize - return current record size - 4 (length of data)
  # 
  #   usage:
  #     my $dataLen = $gds2File -> dataSize;
  # 
  def dataSize
    @Length - 4
  end
  ################################################################################

  # == returnUnitsAsArray - return user units and database units as a 2 element array
  # 
  #   usage:
  #     my ($uu,$dbu) = $gds2File -> returnUnitsAsArray;
  # 
  # 

  def returnUnitsAsArray
    return [@UUnits, @DBUnits]  if self.isUnits
    return []
  end
  ################################################################################

  #######
  def subbyte ## GDS2::version();
    (what,where,howmuch) = @_
    unpack("x#{where} C#{howmuch}", what)
  end
  ################################################################################

  # == version - return GDS2 module version string
  # 

  #######
  def version ## GDS2::version();

    return VERSION
  end
  ################################################################################

  # == version - return GDS2 module revision string
  # 

  #######
  def revision ## GDS2::revision();

    return REVISION
  end
  ################################################################################

  def getElmSpace
    return @elmspace
  end
  ################################################################################

  def putElmSpace
    @elmspace = shift
  end
  ################################################################################

  def getStrSpace
    return @strspace
  end
  ################################################################################

  def putStrSpace
    @strspace = shift
  end
  ################################################################################

end

# = GDS2 Stream Format
# 
#  #########################################################################################
#  #
#  # Gds2 stream format is composed of variable length records. The mininum
#  # length record is 4 bytes. The 1st 2 bytes of a record contain a count (in 8 bit
#  # bytes) of the total record length.  The 3rd byte of the header is the record
#  # type. The 4th byte describes the type of data contained w/in the record. The
#  # 5th through last bytes are data.
#  #
#  # If the output file is a mag tape, then the records of the library are written
#  # out in 2048-byte physical blocks. Records may overlap block boundaries.
#  # For this reason I think gds2 is often padded with null bytes so that the
#  # file size ends up being a multiple of 2048.
#  #
#  # A null word consists of 2 consecutive zero bytes. Use null words to fill the
#  # space between:
#  #     o the last record of a library and the end of its block
#  #     o the last record of a tape in a mult-reel stream file.
#  #
#  # DATA TYPE        VALUE  RECORD
#  # ---------        -----  -----------------------
#  # no data present     0   4 byte header + 0
#  #
#  # Bit Array           1   4 byte header + 2 bytes data
#  #
#  # 2byte Signed Int    2  SMMMMMMM MMMMMMMM  -> S - sign ;  M - magnitude.
#  #                        Twos complement format, with the most significant byte first.
#  #                        I.E.
#  #                        0x0001 = 1
#  #                        0x0002 = 2
#  #                        0x0089 = 137
#  #                        0xffff = -1
#  #                        0xfffe = -2
#  #                        0xff77 = -137
#  #
#  # 4byte Signed Int    3  SMMMMMMM MMMMMMMM MMMMMMMM MMMMMMMM
#  #
#  # 8byte Real          5  SEEEEEEE MMMMMMMM MMMMMMMM MMMMMMMM E-expon in excess-64
#  #                        MMMMMMMM MMMMMMMM MMMMMMMM MMMMMMMM representation
#  #
#  #                        Mantissa == pos fraction >=1/16 && <1 bit 8==1/2, 9==1/4 etc...
#  #                        The first bit is the sign (1 = negative), the next 7 bits
#  #                        are the exponent, you have to subtract 64 from this number to
#  #                        get the real value. The next seven bytes are the mantissa in
#  #                        4 word floating point representation.
#  #
#  #
#  # string              6  odd length strings must be padded w/ null character and
#  #                        byte count+=1
#  #
#  #########################################################################################
# 
# 
# = Backus-naur representation of GDS2 Stream Syntax
# 
#  ################################################################################
#  #  <STREAM FORMAT>::= HEADER BGNLIB [LIBDIRSIZE] [SRFNAME] [LIBSECR]           #
#  #                     LIBNAME [REFLIBS] [FONTS] [ATTRTABLE] [GENERATIONS]      #
#  #                     [<FormatType>] UNITS {<structure>}* ENDLIB               #
#  #                                                                              #
#  #  <FormatType>::=    FORMAT | FORMAT {MASK}+ ENDMASKS                         #
#  #                                                                              #
#  #  <structure>::=     BGNSTR STRNAME [STRCLASS] {<element>}* ENDSTR            #
#  #                                                                              #
#  #  <element>::=       {<boundary> | <path> | <SREF> | <AREF> | <text> |        #
#  #                      <node> | <box} {<property>}* ENDEL                      #
#  #                                                                              #
#  #  <boundary>::=      BOUNDARY [ELFLAGS] [PLEX] LAYER DATATYPE XY              #
#  #                                                                              #
#  #  <path>::=          PATH [ELFLAGS] [PLEX] LAYER DATATYPE [PATHTYPE]          #
#  #                     [WIDTH] [BGNEXTN] [ENDEXTN] [XY]                         #
#  #                                                                              #
#  #  <SREF>::=          SREF [ELFLAGS] [PLEX] SNAME [<strans>] XY                #
#  #                                                                              #
#  #  <AREF>::=          AREF [ELFLAGS] [PLEX] SNAME [<strans>] COLROW XY         #
#  #                                                                              #
#  #  <text>::=          TEXT [ELFLAGS] [PLEX] LAYER <textbody>                   #
#  #                                                                              #
#  #  <textbody>::=      TEXTTYPE [PRESENTATION] [PATHTYPE] [WIDTH] [<strans>] XY #
#  #                     STRING                                                   #
#  #                                                                              #
#  #  <strans>::=        STRANS [MAG] [ANGLE]                                     #
#  #                                                                              #
#  #  <node>::=          NODE [ELFLAGS] [PLEX] LAYER NODETYPE XY                  #
#  #                                                                              #
#  #  <box>::=           BOX [ELFLAGS] [PLEX] LAYER BOXTYPE XY                    #
#  #                                                                              #
#  #  <property>::=      PROPATTR PROPVALUE                                       #
#  ################################################################################
# 
# 
# = GDS2 Stream Record Datatypes
# 
#  ################################################################################
#  NO_REC_DATA   =  0;
#  BIT_ARRAY     =  1;
#  INTEGER_2     =  2;
#  INTEGER_4     =  3;
#  REAL_4        =  4; ## NOT supported, never really used
#  REAL_8        =  5;
#  ASCII_STRING  =  6;
#  ################################################################################
# 
# 
# = GDS2 Stream Record Types
# 
#  ################################################################################
#  HEADER        =  0;   ## 2-byte Signed Integer
#  BGNLIB        =  1;   ## 2-byte Signed Integer
#  LIBNAME       =  2;   ## ASCII String
#  UNITS         =  3;   ## 8-byte Real
#  ENDLIB        =  4;   ## no data present
#  BGNSTR        =  5;   ## 2-byte Signed Integer
#  STRNAME       =  6;   ## ASCII String
#  ENDSTR        =  7;   ## no data present
#  BOUNDARY      =  8;   ## no data present
#  PATH          =  9;   ## no data present
#  SREF          = 10;   ## no data present
#  AREF          = 11;   ## no data present
#  TEXT          = 12;   ## no data present
#  LAYER         = 13;   ## 2-byte Signed Integer
#  DATATYPE      = 14;   ## 2-byte Signed Integer
#  WIDTH         = 15;   ## 4-byte Signed Integer
#  XY            = 16;   ## 4-byte Signed Integer
#  ENDEL         = 17;   ## no data present
#  SNAME         = 18;   ## ASCII String
#  COLROW        = 19;   ## 2 2-byte Signed Integer <= 32767
#  TEXTNODE      = 20;   ## no data present
#  NODE          = 21;   ## no data present
#  TEXTTYPE      = 22;   ## 2-byte Signed Integer
#  PRESENTATION  = 23;   ## Bit Array. One word (2 bytes) of bit flags. Bits 11 and
#                        ##   12 together specify the font 00->font 0 11->font 3.
#                        ##   Bits 13 and 14 specify the vertical presentation, 15
#                        ##   and 16 the horizontal presentation. 00->'top/left' 01->
#                        ##   middle/center 10->bottom/right bits 1-10 were reserved
#                        ##   for future use and should be 0.
#  SPACING       = 24;   ## discontinued
#  STRING        = 25;   ## ASCII String <= 512 characters
#  STRANS        = 26;   ## Bit Array: 2 bytes of bit flags for graphic presentation
#                        ##   The 1st (high order or leftmost) bit specifies
#                        ##   reflection. If set then reflection across the X-axis
#                        ##   is applied before rotation. The 14th bit flags
#                        ##   absolute mag, the 15th absolute angle, the other bits
#                        ##   were reserved for future use and should be 0.
#  MAG           = 27;   ## 8-byte Real
#  ANGLE         = 28;   ## 8-byte Real
#  UINTEGER      = 29;   ## UNKNOWN User int, used only in Calma V2.0
#  USTRING       = 30;   ## UNKNOWN User string, used only in Calma V2.0
#  REFLIBS       = 31;   ## ASCII String
#  FONTS         = 32;   ## ASCII String
#  PATHTYPE      = 33;   ## 2-byte Signed Integer
#  GENERATIONS   = 34;   ## 2-byte Signed Integer
#  ATTRTABLE     = 35;   ## ASCII String
#  STYPTABLE     = 36;   ## ASCII String "Unreleased feature"
#  STRTYPE       = 37;   ## 2-byte Signed Integer "Unreleased feature"
#  EFLAGS        = 38;   ## BIT_ARRAY  Flags for template and exterior data.
#                        ## bits 15 to 0, l to r 0=template, 1=external data, others unused
#  ELKEY         = 39;   ## INTEGER_4  "Unreleased feature"
#  LINKTYPE      = 40;   ## UNKNOWN    "Unreleased feature"
#  LINKKEYS      = 41;   ## UNKNOWN    "Unreleased feature"
#  NODETYPE      = 42;   ## INTEGER_2  Nodetype specification. On Calma this could be 0 to 63,
#                        ##   GDSII allows 0 to 255. Of course a 16 bit integer allows up to 65535...
#  PROPATTR      = 43;   ## INTEGER_2  Property number.
#  PROPVALUE     = 44;   ## STRING     Property value. On GDSII, 128 characters max, unless an
#                        ##   SREF, AREF, or NODE, which may have 512 characters.
#  BOX           = 45;   ## NO_DATA    The beginning of a BOX element.
#  BOXTYPE       = 46;   ## INTEGER_2  Boxtype specification.
#  PLEX          = 47;   ## INTEGER_4  Plex number and plexhead flag. The least significant bit of
#                        ##   the most significant byte is the plexhead flag.
#  BGNEXTN       = 48;   ## INTEGER_4  Path extension beginning for pathtype 4 in Calma CustomPlus.
#                        ##   In database units, may be negative.
#  ENDEXTN       = 49;   ## INTEGER_4  Path extension end for pathtype 4 in Calma CustomPlus. In
#                        ##   database units, may be negative.
#  TAPENUM       = 50;   ## INTEGER_2  Tape number for multi-reel stream file.
#  TAPECODE      = 51;   ## INTEGER_2  Tape code to verify that the reel is from the proper set.
#                        ##   12 bytes that are supposed to form a unique tape code.
#  STRCLASS      = 52;   ## BIT_ARRAY  Calma use only.
#  RESERVED      = 53;   ## INTEGER_4  Used to be NUMTYPES per Calma GDSII Stream Format Manual, v6.0.
#  FORMAT        = 54;   ## INTEGER_2  Archive or Filtered flag.  0: Archive 1: filtered
#  MASK          = 55;   ## STRING     Only in filtered streams. Layers and datatypes used for mask
#                        ##   in a filtered stream file. A string giving ranges of layers and datatypes
#                        ##   separated by a semicolon. There may be more than one mask in a stream file.
#  ENDMASKS      = 56;   ## NO_DATA    The end of mask descriptions.
#  LIBDIRSIZE    = 57;   ## INTEGER_2  Number of pages in library director, a GDSII thing, it seems
#                        ##   to have only been used when Calma INFORM was creating a new library.
#  SRFNAME       = 58;   ## STRING     Calma "Sticks"(c) rule file name.
#  LIBSECUR      = 59;   ## INTEGER_2  Access control list stuff for CalmaDOS, ancient. INFORM used
#                        ##   this when creating a new library. Had 1 to 32 entries with group
#                        ##   numbers, user numbers and access rights.
# 

