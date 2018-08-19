require 'pp'

class GDS2
  VERSION = '3.35'
  ## Note: '@ ( # )' used by the what command  E.g. what GDS2.pm
  REVISION = '@(#) $Id: GDS2.pm,v $ $Revision: 3.35 $ $Date: 2017-10-04 03:27:57-06 $'

  #
  # = NAME
  #
  # GDS2 - GDS2 stream module
  #
  # = SYNOPSIS
  #
  # This is GDS2, a module for creating programs to read and/or write GDS2 files.
  #
  # = COPYRIGHT
  #
  # Authors:
  #
  # Ben Bowers (c) 2018
  # Ken Schumack (c) 1999-2017 (Original perl version)
  # All rights reserved.
  #
  # This module is free software. It may be used, redistributed
  # and/or modified under the terms of the BSD 2-clause License.
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
  UNKNOWN = -1

  HAVE_FLOCK = true ## some systems still may not have this...manually change
  #    use Config
  #    use IO::File
  # end

  # isLittleEndian = false; #default - was developed on a BigEndian machine
  # isLittleEndian = true if config['byteorder'] =~ /^1/ ; ## Linux mswin32 cygwin vms

  # Unclear if we need bigendian support or how to do this properly with Ruby
  # for now hardcode with a class method
  def self.isLittleEndian
    true
  end

  ############################################################################
  ## GDS2 STREAM RECORD DATATYPES
  ############################################################################
  NO_REC_DATA  = 0
  BIT_ARRAY    = 1
  INTEGER_2    = 2
  INTEGER_4    = 3
  # REAL_4 is NOT supported, should not be found in any GDS2
  REAL_4       = 4
  REAL_8       = 5
  ASCII_STRING = 6
  ############################################################################

  ############################################################################
  ## GDS2 STREAM RECORD TYPES
  ############################################################################

  ## 2-byte Signed Integer
  HEADER       =  0;   

  ## 2-byte Signed Integer
  BGNLIB       =  1;   

  ## ASCII String
  LIBNAME      =  2;   

  ## 8-byte Real
  UNITS        =  3;   
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

  # BIT_ARRAY  Flags for template and exterior data.  bits 15 to 0, l to r 0=template,
  # 1=external data, others unused
  EFLAGS       = 38;   
  
  ## INTEGER_4  "Unreleased feature"
  ELKEY        = 39;   

  ## UNKNOWN    "Unreleased feature"
  LINKTYPE     = 40;   

  ## UNKNOWN    "Unreleased feature"
  LINKKEYS     = 41;   

  ## INTEGER_2  Nodetype specification. On Calma this could be 0 to 63, GDSII allows 0 to 255.
  ##   Of course a 2 byte integer allows up to 65535...
  NODETYPE     = 42;   

  ## INTEGER_2  Property number.
  PROPATTR     = 43;   

  ## STRING     Property value. On GDSII, 128 characters max, unless an SREF, AREF, or NODE,
  ## which may have 512 characters.
  PROPVALUE    = 44;   

  ## NO_DATA    The beginning of a BOX element.
  BOX          = 45;   

  ## INTEGER_2  Boxtype specification.
  BOXTYPE      = 46;   

  ## INTEGER_4  Plex number and plexhead flag. The least significant bit of the most significant
  ##    byte is the plexhead flag.
  PLEX         = 47;

  ## INTEGER_4  Path extension beginning for pathtype 4 in Calma CustomPlus. In database units,
  ##    may be negative.
  BGNEXTN      = 48;

  ## INTEGER_4  Path extension end for pathtype 4 in Calma CustomPlus. In database units, may be negative.
  ENDEXTN      = 49;   

  ## INTEGER_2  Tape number for multi-reel stream file.
  TAPENUM      = 50;   

  ## INTEGER_2  Tape code to verify that the reel is from the proper set. 12 bytes that are
  ## supposed to form a unique tape code.
  TAPECODE     = 51;   

  ## BIT_ARRAY  Calma use only.
  STRCLASS     = 52;   

  ## INTEGER_4  Used to be NUMTYPES per Calma GDSII Stream Format Manual, v6.0.
  RESERVED     = 53;   

  ## INTEGER_2  Archive or Filtered flag.  0: Archive 1: filtered
  FORMAT       = 54;   

  ## STRING     Only in filtered streams. Layers and datatypes used for mask in a filtered
  ##   stream file. A string giving ranges of layers and datatypes separated by a semicolon.
  ##   There may be more than one mask in a stream file.
  MASK         = 55;   

  ## NO_DATA    The end of mask descriptions.
  ENDMASKS     = 56;   

  ## INTEGER_2  Number of pages in library director, a GDSII thing, it seems to have only been
  ##   used when Calma INFORM was creating a new library.
  LIBDIRSIZE   = 57;

  ## STRING     Calma "Sticks"(c) rule file name.
  SRFNAME      = 58;

  ## INTEGER_2  Access control list stuff for CalmaDOS, ancient. INFORM used this when creating
  ##   a new library. Had 1 to 32 entries with group numbers, user numbers and access rights.
  LIBSECUR     = 59;
  #############################################################################################

  RECORDTYPENUMBERS = {
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
    'PRESENTATION' => PRESENTATION,
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
    'LIBSECUR'    => LIBSECUR
  }.freeze

  # For ascii print of GDS
  RECORDTYPESTRINGS = [ 
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
    'LIBSECUR'
  ].freeze

  # For compact ascii print of GDS (GDT format) see http://sourceforge.net/projects/gds2/
  COMPACTRECORDTYPESTRINGS = [ 
    'gds2{',          # HEADER
    '',               # BGNLIB
    'lib',            # LIBNAME
    '',               # UNITS
    '}',              # ENDLIB
    'cell{',          # BGNSTR
    '',               # STRNAME
    '}',              # ENDSTR
    'b{',             # BOUNDARY
    'p{',             # PATH
    's{',             # SREF
    'a{',             # AREF
    't{',             # TEXT
    '',               # LAYER
    ' dt',            # DATATYPE
    ' w',             # WIDTH
    ' xy(',           # XY  #)
    '}',              # ENDEL
    '',               # SNAME
    ' cr',            # COLROW
    ' tn',            # TEXTNODE
    ' no',            # NODE
    ' tt',            # TEXTTYPE
    '',               # PRESENTATION'
    ' sp',            # SPACING
    '',               # STRING
    '',               # STRANS
    ' m',             # MAG
    ' a',             # ANGLE
    ' ui',            # UINTEGER
    ' us',            # USTRING
    ' rl',            # REFLIBS
    ' f',             # FONTS
    ' pt',            # PATHTYPE
    ' gen',           # GENERATIONS
    ' at',            # ATTRTABLE
    ' st',            # STYPTABLE
    ' strt',          # STRTYPE
    ' ef',            # EFLAGS
    ' ek',            # ELKEY
    ' lt',            # LINKTYPE
    ' lk',            # LINKKEYS
    ' nt',            # NODETYPE
    ' ptr',           # PROPATTR
    ' pv',            # PROPVALUE
    ' bx',            # BOX
    ' bt',            # BOXTYPE
    ' px',            # PLEX
    ' bx',            # BGNEXTN
    ' ex',            # ENDEXTN
    ' tnum',          # TAPENUM
    ' tcode',         # TAPECODE
    ' strc',          # STRCLASS
    ' resv',          # RESERVED
    ' fmt',           # FORMAT
    ' msk',           # MASK
    ' emsk',          # ENDMASKS
    ' lds',           # LIBDIRSIZE
    ' srfn',          # SRFNAME
    ' libs',          # LIBSECUR
  ].freeze

  ###################################################
  # Hash of record-type to the data-type
  RECORDTYPEDATA = {
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
    'SPACING'      => UNKNOWN, # INTEGER_4, discontinued
    'STRING'       => ASCII_STRING,
    'STRANS'       => BIT_ARRAY,
    'MAG'          => REAL_8,
    'ANGLE'        => REAL_8,
    'UINTEGER'     => UNKNOWN, # INTEGER_4, no longer used
    'USTRING'      => UNKNOWN, # ASCII_STRING, no longer used
    'REFLIBS'      => ASCII_STRING,
    'FONTS'        => ASCII_STRING,
    'PATHTYPE'     => INTEGER_2,
    'GENERATIONS'  => INTEGER_2,
    'ATTRTABLE'    => ASCII_STRING,
    'STYPTABLE'    => ASCII_STRING, # unreleased feature
    'STRTYPE'      => INTEGER_2, # INTEGER_2, unreleased feature
    'EFLAGS'       => BIT_ARRAY,
    'ELKEY'        => INTEGER_4, # INTEGER_4, unreleased feature
    'LINKTYPE'     => INTEGER_2, # unreleased feature
    'LINKKEYS'     => INTEGER_4, # unreleased feature
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
    'LIBDIRSIZE'   => UNKNOWN, # INTEGER_2
    'SRFNAME'      => ASCII_STRING,
    'LIBSECUR'     => UNKNOWN, # INTEGER_2,
  }

  # This is the default class for the GDS2 object to use when all else fails.
  # GDS2::defaultclass = 'GDS2' unless defined GDS2::defaultclass

  @g_gdtstring = ''
  @g_epsilon = '0.001'; ## to take care of floating point representation problems
  @g_fltlen = 3
  # it's own name space...
  begin
    fltLenTmp = format('%0.99f', (1.0 / 3.0)).sub(/^0.(3+).*/, '\\1').length - 10
    if fltLenTmp > @g_epsilon.length # try to make smaller if we can...
      @g_epsilon = format("%0.#{fltLenTmp}f1", 0)
      @g_fltlen = fltLenTmp
    end
  end
  @g_epsilon = @g_epsilon.to_f # ensure it's a number

  # More class inst vars.  Probably better ways to do this..
  @strspace = ''
  @elmspace = ''

  # class method accessors to class-instance-variables
  class << self
    attr_reader :g_fltlen, :g_epsilon
    attr_accessor :strspace, :elmspace
  end

  ############################################################################

  # = Examples
  #
  #   Layer change:
  #     here's a bare bones script to change all layer 59 to 66 given a file to
  #     read and a new file to create.
  #     #!/usr/bin/perl -w
  #     require 'gds2'
  #     $fileName1 = $ARGV[0];
  #     $fileName2 = $ARGV[1];
  #     gds2File1 = new GDS2(-fileName => $fileName1);
  #     gds2File2 = new GDS2(-fileName => ">$fileName2");
  #     while ($record = gds2File1.readGds2Record)
  #         if (gds2File1.returnLayer == 59)
  #             gds2File2.printLayer(-num=>66);
  #         else
  #             gds2File2.printRecord(-data=>$record);
  #         end
  #     end
  #
  #
  #   Gds2 dump:
  #     here's a complete program to dump the contents of a stream file.
  #     #!/usr/bin/perl -w
  #     require 'gds2'
  #     $\="\n";
  #     gds2File = new GDS2(-fileName=>$ARGV[0]);
  #     while (gds2File.readGds2Record)
  #     {
  #         print gds2File.returnRecordAsString;
  #     }
  #
  #
  #   Gds2 dump in GDT format: which is smaller and easier to parse - http://sourceforge.net/projects/gds2/
  #     #!/usr/bin/perl -w
  #     require 'gds2'
  #     gds2File = new GDS2(-fileName=>$ARGV[0]);
  #     while (gds2File.readGds2Record)
  #     {
  #         print gds2File.returnRecordAsString(-compact=>1);
  #     }
  #
  #   Dump from the command line of a bzip2 compressed file:
  #   perl -MGDS2 -MFileHandle -MIPC::Open3 -e '$f1=new FileHandle;$f0=new FileHandle;open3($f0,$f1,$f1,"bzcat test.gds.bz2");gds=new GDS2(-fileHandle=>$f1);while(gds->readGds2Record){print gds->returnRecordAsString(-compact=>1)}'
  #
  #   Create a complete GDS2 stream file from scratch:
  #     #!/usr/bin/perl -w
  #     require 'gds2'
  #     gds2File = new GDS2(-fileName=>'>test.gds');
  #     gds2File.printInitLib(-name=>'testlib');
  #     gds2File.printBgnstr(-name=>'test');
  #     gds2File.printPath(
  #                     -layer=>6,
  #                     -pathType=>0,
  #                     -width=>2.4,
  #                     -xy=>[0,0, 10.5,0, 10.5,3.3],
  #                  );
  #     gds2File.printSref(
  #                     -name=>'contact',
  #                     -xy=>[4,5.5],
  #                  );
  #     gds2File.printAref(
  #                     -name=>'contact',
  #                     -columns=>2,
  #                     -rows=>3,
  #                     -xy=>[0,0, 10,0, 0,15],
  #                  );
  #     gds2File.printEndstr;
  #     gds2File.printBgnstr(-name => 'contact');
  #     gds2File.printBoundary(
  #                     -layer=>10,
  #                     -xy=>[0,0, 1,0, 1,1, 0,1],
  #                  );
  #     gds2File.printEndstr;
  #     gds2File.printEndlib();
  #
  # ############################################################################
  #
  # = METHODS
  #
  # == new - open gds2 file
  #
  #   usage:
  #   gds2File  = GDS2.new(fileName: "filename.gds2"); ## to read
  #   gds2File2 = GDS2.new(fileName: ">filename.gds2"); ## to write
  #
  #   -or- provide your own fileHandle:
  #
  #   gds2File  = GDS2.new(fileHandle: $fh); ## e.g. to attach to a compression/decompression pipe
  #

  def initialize(fileName: nil, fileHandle: nil, resolution: 1000, mode: 'r')
    if fileName && fileHandle
      raise 'new expects a gds2 file name -OR- a file handle. Do not give both.'
    end
    unless fileName || fileHandle

      raise "new expects a fileName: 'name' OR fileHandle: fh"
    end
    lockMode = File::LOCK_SH; ## default
    if fileName
      openModeNum = File::RDONLY
      if mode.to_s == 'w'
        openModeNum = File::WRONLY | File::CREAT
        lockMode = File::LOCK_EX
      elsif mode.to_s == 'a'
        openModeNum = File::WRONLY | File::APPEND
        lockMode = File::LOCK_EX
      end
      # fileHandle = new IO::File
      fileHandle = File.open(fileName, openModeNum | File::BINARY)
      # or raise "Unable to open #{fileName} because"
      if HAVE_FLOCK
        fileHandle.flock(lockMode) || raise("File lock on #{fileHandle.path} failed")
      end
    end
    raise "new expects a positive integer resolution. (#{resolution})" if resolution.to_i <= 0

    @Fd         = fileHandle.fileno
    @FileHandle = fileHandle
    @FileName   = fileName; ## the gds2 filename
    @BytesDone  = 0;         ## total file size so far
    @EOLIB      = false;     ## end of library flag
    @INHEADER   = UNKNOWN;   ## in header? flag true | false | UNKNOWN
    @INDATA     = false;     ## in data? flag true | false
    @Length     = 0;         ## length of data
    @DataType   = UNKNOWN;   ## one of 7 gds datatypes
    @UUnits     = -1.0;      ## for gds2 file  e.g. 0.001
    @DBUnits    = -1.0;      ## for gds2 file  e.g. 1e-9
    @Record     = '';        ## the whole record as found in gds2 file
    @RecordType = UNKNOWN
    @DataIndex  = 0
    @RecordData = ()
    @CurrentDataList = ''
    @InBoundary = false;     ##
    @InTxt      = false;     ##
    @DateFld    = 0; ##
    @Resolution = resolution
    @UsingPrettyPrint = false; ## print as string ...
  end
  ############################################################################
  ############################################################################
  # common integer resolution snapping function
  ## e.g. 3.4 in -> 3400 out
  def snap_int (num)
    if num >= 0
      ((num * @Resolution) + GDS2::g_epsilon).to_i
    else
      ((num * @Resolution) - GDS2::g_epsilon).to_i
    end
  end

  #######
  # private method to clean up number
  def cleanExpNum(inum)
    num = format("%0.#{GDS2.g_fltlen}e", inum)
    num.sub!(/([1-9])0+e/, "\\1e")
    num.sub!(/(\d)\.0+e/, "\\1e")
    num
  end

  ############################################################################
  # private method to clean up number
  def cleanFloatNum(inum)
    num = format("%0.#{GDS2.g_fltlen}f", inum)
    num.sub!(/([1-9])0+$/, "\\1")
    num.sub!(/(\d)\.0+$/, "\\1")
    num.to_f
  end

  ############################################################################
  # == fileNum - file number...
  #
  #   usage:
  #
  def fileNum(*_arg)
    @Fd.to_i
  end
  ############################################################################

  # == close - close gds2 file
  #
  #   usage:
  #   gds2File.close;
  #    -or-
  #   gds2File.close(-markEnd=>1); ## -- some systems have trouble closing files
  #   gds2File.close(-pad=>2048);  ## -- pad end with \0's till file size is a
  #                                    ## multiple of number. Note: old reel to reel tapes on Calma
  #                                    ## systems used 2048 byte blocks
  #

  def close (markEnd: nil, pad: nil)
    if markEnd
      fh = @FileHandle
      fh.print "\x1a\x04"; # a ^Z and a ^D
      @BytesDone += 2
    end
    if pad && (pad > 0)
      fh = @FileHandle
      fh.flush
      fh.seek(0, SEEK_END)
      fileSize = fh.tell
      padSize = pad - (fileSize % pad)
      padSize = 0 if padSize == pad
      (0..padSize).each do
        fh.print "\0" ## a null
      end
    end
    @FileHandle.close
  end
  ############################################################################

  ############################################################################
  # High Level Write Methods
  ############################################################################

  # == printInitLib() - Does all the things needed to start a library, writes HEADER,BGNLIB,LIBNAME,
  #  and UNITS records
  #
  # The default is to create a library with a default unit of 1 micron that has a resolution of 1000.
  # To get this set uUnit to 0.001 (1/1000) and the dbUnit to 1/1000th of a micron (1e-9).
  #    usage:
  #      gds2File.printInitLib(-name    => "testlib",  ## required
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

  def printInitLib(name: nil, isoDate: false, uUnit: false, dbUnit: 1e-9)
    raise "printInitLib expects a library name. Missing name: 'name'" unless name

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

    t = Time.now
    isoadjust = isoDate ? 1900 : 0  ## Cadence likes year left "as is". GDS format supports year number up to 65535 -- 101 vs 2001
    printGds2Record(type: 'HEADER', data: 3); ## GDS2 HEADER
    printGds2Record(type: 'BGNLIB', data: [t.year + isoadjust, t.mon, t.mday, t.hour, t.min, t.sec,
                                           t.year + isoadjust, t.mon, t.mday, t.hour, t.min, t.sec])
    printGds2Record(type: 'LIBNAME', data: name)
    printGds2Record(type: 'UNITS', data: [uUnit, dbUnit])
  end
  ############################################################################

  # == printBgnstr - Does all the things needed to start a structure definition
  #
  #    usage:
  #     gds2File.printBgnstr(name: "nand3" ## writes BGNSTR and STRNAME records
  #                          isoDate: => 1|0  ## (optional) use ISO 4 digit date 2001 vs 101
  #                         )
  #
  #    note:
  #      remember to close with printEndstr()
  #

  def printBgnstr(name: nil, isoDate: false, createTime: Time.now, modTime: Time.now)
    raise "bgnStr expects a structure name. Missing name: 'name'" unless name
    ct = createTime
    mt = modTime
    isoyear = isoDate ? 1900 : 0 ## 2001 vs 101
    printGds2Record(type: 'BGNSTR', data: [ct.year+isoyear, ct.mon, ct.mday, ct.hour, ct.min, ct.sec,
                                           mt.year+isoyear, mt.mon, mt.mday, mt.hour, mt.min, mt.sec])
    printGds2Record(type: 'STRNAME', data: name)
  end

  ############################################################################
  # == printPath - prints a gds2 path
  #
  #   usage:
  #     gds2File.printPath(
  #                     -layer=>#,
  #                     -dataType=>#,     ##optional
  #                     -pathType=>#,
  #                     -width=>#.#,
  #                     -unitWidth=>#,    ## (optional) directly specify width in data base units (vs -width which is multipled by resolution)
  #
  #                     -xy=>Array,     ## array of reals
  #                       # -or-
  #                     -xyInt=>Array,  ## array of internal ints (optional -wks better if you are modifying an existing GDS2 file)
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
  def printPath(layer: 0, dataType: 0, pathType: 0,
                bgnExtn: 0, endExtn: 0, unitWidth: nil, width: nil,
                xy: nil, xyInt: nil)
    resolution = @Resolution

    widthi = 0
    widthi = unitWidth.to_i if unitWidth && (unitWidth >= 0)
    if width && (width >= 0.0)
      widthi = ((width * resolution) + GDS2::g_epsilon).to_i
    end
    width = widthi
    #### -xyInt most useful if reading and modifying... -xy if creating from scratch
    ## $xyInt should be a reference to an array of internal GDS2 format integers
    ## $xy should be a reference to an array of reals
    xyTmp = []; # #don't pollute array passed in
    unless xy || xyInt
      raise "printPath expects an xy array reference. Missing xy: Array"
    end
    if xyInt
      xy = xyInt
      resolution = 1
    end
    printGds2Record(type: 'PATH')
    printGds2Record(type: 'LAYER', data: layer)
    printGds2Record(type: 'DATATYPE', data: dataType)
    printGds2Record(type: 'PATHTYPE', data: pathType) if pathType
    printGds2Record(type: 'WIDTH', data: width) if width
    if pathType == 4
      printGds2Record(type: 'BGNEXTN', data: bgnExtn); ## int used with resolution
      printGds2Record(type: 'ENDEXTN', data: endExtn); ## int used with resolution
    end

    xy.each do |xyi|
      ## e.g. 3.4 in.3400 out
      xyTmp << snap_int(xyi)
    end

    if bgnExtn || endExtn  ## we have to convert

      bgnX1 = xyTmp[0]
      bgnY1 = xyTmp[1]
      bgnX2 = xyTmp[2]
      bgnY2 = xyTmp[3]
      endX1 = xyTmp[xyTmp.length - 1]
      endY1 = xyTmp[xyTmp.length]
      endX2 = xyTmp[xyTmp.length - 3]
      endY2 = xyTmp[xyTmp.length - 2]
      if bgnExtn

        if bgnX1 == bgnX2  # vertical ...modify 1st Y

          if bgnY1 < bgnY2 ## points down

            xyTmp[1] -= bgnExtn
            xyTmp[1] += int(width / 2) if pathType != 0

          else ## points up

            xyTmp[1] += bgnExtn
            xyTmp[1] -= int(width / 2) if pathType != 0
          end

        elsif bgnY1 == bgnY2 # horizontal ...modify 1st X

          if bgnX1 < bgnX2 ## points left

            xyTmp[0] -= bgnExtn
            xyTmp[0] += int(width / 2) if pathType != 0

          else ## points up

            xyTmp[0] += bgnExtn
            xyTmp[0] -= int(width / 2) if pathType != 0
          end
        end
      end

      if endExtn

        if endX1 == endX2 # vertical ...modify last Y

          if endY1 < endY2 ## points down

            xyTmp[xyTmp.length] -= endExtn
            xyTmp[xyTmp.length] += (width / 2).to_i if pathType != 0

          else ## points up

            xyTmp[xyTmp.length] += endExtn
            xyTmp[xyTmp.length] -= (width / 2).to_i if pathType != 0
          end

        elsif endY1 == endY2 # horizontal ...modify last X

          if endX1 < endX2 ## points left

            xyTmp[xyTmp.length - 1] -= endExtn
            xyTmp[xyTmp.length - 1] += (width / 2).to_i if pathType != 0

          else ## points up

            xyTmp[xyTmp.length - 1] += endExtn
            xyTmp[xyTmp.length - 1] -= (width / 2).to_i if pathType != 0
          end
        end
      end
    end
    printGds2Record(type: 'XY', data: xyTmp)
    printGds2Record(type: 'ENDEL')
  end
  ############################################################################

  # == printBoundary - prints a gds2 boundary
  #
  #   usage:
  #     gds2File.printBoundary(
  #                     -layer=>#,
  #                     -dataType=>#,
  #
  #                     -xy=>Array,     ## ref to array of reals
  #                       # -or-
  #                     -xyInt=>Array,  ## ref to array of internal ints (optional -wks better if you are modifying an existing GDS2 file)
  #                  );
  #
  #   note:
  #     layer defaults to 0 if -layer not used
  #     dataType defaults to 0 if -dataType not used
  #

  #  <boundary>::= BOUNDARY [ELFLAGS] [PLEX] LAYER DATATYPE XY
  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  def printBoundary(*arg, layer: 0, dataType: 0, xy: nil, xyInt: nil)
    resolution = @Resolution
    #### -xyInt most useful if reading and modifying... -xy if creating from scratch
    ## xyInt should be a reference to an array of internal GDS2 format integers
    ## xy should be a reference to an array of reals
    xyTmp = []; # #don't pollute array passed in
    unless  xy || xyInt
      raise "printBoundary expects an xy array reference. Missing -xy => \\\#{array}"
    end
    if xyInt
      xy = xyInt
      resolution = 1
    end
    printGds2Record(type: 'BOUNDARY')
    printGds2Record(type: 'LAYER', data: layer)
    printGds2Record(type: 'DATATYPE', data: dataType)
    if (numPoints = xy.length + 1) < 6

      raise 'printBoundary expects an xy array of at leasts 3 coordinates'
    end
    xy.each do |xyi|
      ## e.g. 3.4 in -> 3400 out
      xyTmp << snap_int(xyi)
    end
    ## gds expects square to have 5 coords (closure)
    if (xy[0] != (xy[(xy.length - 1)])) || (xy[1] != (xy[xy.length]))
      xyTmp << snap_int(xy[0])
      xyTmp << snap_int(xy[1])
    end
    printGds2Record(type: 'XY', data: xyTmp)
    printGds2Record(type: 'ENDEL')
  end
  ############################################################################

  # == printSref - prints a gds2 Structure REFerence
  #
  #   usage:
  #     gds2File.printSref(
  #                     -name=>string,   ## Name of structure
  #
  #                     -xy=>Array,    ## ref to array of reals
  #                       # -or-
  #                     -xyInt=>Array, ## ref to array of internal ints (optional -wks better than -xy if you are modifying an existing GDS2 file)
  #
  #                     -angle=>#.#,     ## (optional) Default is 0.0
  #                     -mag=>#.#,       ## (optional) Default is 1.0
  #                     -reflect=>0|1    ## (optional)
  #                  );
  #
  #   note:
  #     best not to specify angle or mag if not needed
  #

  # <SREF>::= SREF [ELFLAGS] [PLEX] SNAME [<strans>] XY
  #  <strans>::=   STRANS [MAG] [ANGLE]
  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  def printSref(*arg, name: nil, xy: nil, xyInt: nil, angle: nil, mag: 1.0, reflect: nil)
    useSTRANS = false
    resolution = @Resolution
    raise "printSref expects a name string. Missing name: 'text'" unless name
    #### -xyInt most useful if reading and modifying... -xy if creating from scratch
    ## $xyInt should be a reference to an array of internal GDS2 format integers
    ## $xy should be a reference to an array of reals
    unless  xy || xyInt
      raise "printSref expects an xy array reference. Missing xy: Array"
    end
    if xyInt
      xy = xyInt
      resolution = 1
    end
    printGds2Record(type: 'SREF')
    printGds2Record(type: 'SNAME', data: name)
    if !reflect || (reflect <= 0)
      reflect = 0
    else

      reflect = 1
      useSTRANS = true
    end

    if !mag || (mag <= 0)
      mag = 0
    else
      mag = cleanFloatNum(mag)
      useSTRANS = true
    end

    if !angle
      angle = -1; # not really... just means not specified
    else

      angle = posAngle(angle)
      useSTRANS = true
    end
    if useSTRANS
      data = reflect.to_s + '0' * 15; ## 16 'bit' string
      printGds2Record(type: 'STRANS', data: data)
      printGds2Record(type: 'MAG', data: mag) if mag
      printGds2Record(type: 'ANGLE', data: angle) if angle >= 0
    end
    xyTmp = []; # #don't pollute array passed in
    xy.each do |xyi| ## e.g. 3.4 in -> 3400 out
      xyTmp << snap_int(xyi)
    end
    printGds2Record(type: 'XY', data: xyTmp)
    printGds2Record(type: 'ENDEL')
  end

  ############################################################################
  # == printAref - prints a gds2 Array REFerence
  #
  #   usage:
  #     gds2File.printAref(
  #                     -name=>string,   ## Name of structure
  #                     -columns=>#,     ## Default is 1
  #                     -rows=>#,        ## Default is 1
  #
  #                     -xy=>Array,    ## ref to array of reals
  #                       # -or-
  #                     -xyInt=>Array, ## ref to array of internal ints (optional -wks better if you are modifying an existing GDS2 file)
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
  # <AREF>::= AREF [ELFLAGS] [PLEX] SNAME [<strans>] COLROW XY
  #  <strans>::= STRANS [MAG] [ANGLE]
  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  def printAref(*arg,name: nil, columns: 1, rows: 1, xy: nil, xyInt: nil, angle: nil, mag: nil, reflect: nil)
    useSTRANS = false
    resolution = @Resolution
    raise "printAref expects a sname string. Missing name: 'text'" unless name
    #### -xyInt most useful if reading and modifying... -xy if creating from scratch
    ## $xyInt should be a reference to an array of internal GDS2 format integers
    ## $xy should be a reference to an array of reals
    unless  xy || xyInt
      raise "printAref expects an xy array reference. Missing -xy => \\\#{array}"
    end
    if xyInt
      xy = xyInt
      resolution = 1
    end
    printGds2Record(type: 'AREF')
    printGds2Record(type: 'SNAME', data: name)

    if !reflect || (reflect <= 0)
      reflect = 0
    else
      reflect = 1
      useSTRANS = true
    end
    
    if !mag || (mag <= 0)
      mag = 0
    else
      mag = cleanFloatNum(mag)
      useSTRANS = true
    end

    if !angle
      angle = -1; # not really... just means not specified
    else
      angle = posAngle(angle)
      useSTRANS = true
    end

    if useSTRANS
      data = reflect.to_s + '0' * 15; ## 16 'bit' string
      printGds2Record(type: 'STRANS', data: data)
      printGds2Record(type: 'MAG', data: mag) if mag
      printGds2Record(type: 'ANGLE', data: angle) if angle >= 0
    end

    columns = if !columns || (columns <= 0)
                1
              else
                columns.to_i
              end

    rows = if !rows || (rows <= 0)
             1
           else
             rows.to_i
           end
    printGds2Record(type: 'COLROW', data: [columns, rows])
    xyTmp = []; # #don't pollute array passed in
    xy.each do |xyi| ## e.g. 3.4 in -> 3400 out
      xyTmp << snap_int(xyi)
    end
    printGds2Record(type: 'XY', data: xyTmp)
    printGds2Record(type: 'ENDEL')
  end
  ############################################################################

  # == printText - prints a gds2 Text
  #
  #   usage:
  #     gds2File.printText(
  #                     -string=>string,
  #                     -layer=>#,      ## Default is 0
  #                     -textType=>#,   ## Default is 0
  #                     -font=>#,       ## 0-3
  #                     -top, or -middle, -bottom,     ##optional vertical presentation
  #                     -left, or -center, or -right,  ##optional horizontal presentation
  #
  #                     -xy=>Array,     ## ref to array of reals
  #                       # -or-
  #                     -xyInt=>Array,  ## ref to array of internal ints (optional -wks better if you are modifying an existing GDS2 file)
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

  # <text>::= TEXT [ELFLAGS] [PLEX] LAYER <textbody>
  #  <textbody>::= TEXTTYPE [PRESENTATION] [PATHTYPE] [WIDTH] [<strans>] XY STRING
  #    <strans>::= STRANS [MAG] [ANGLE]
  ############################################################################
def printText(string: nil, layer: 0, textType: 0, font: nil,
              xy: nil, xyInt: nil,
              x: nil, y: nil,
              angle: nil, mag: nil, reflect: nil
             )
    useSTRANS = false
    raise "printText expects a string. Missing string: 'text'" unless string
    resolution = @Resolution
    #### -xyInt most useful if reading and modifying... -xy if creating from scratch
    ## $xyInt should be a reference to an array of internal GDS2 format integers
    ## $xy should be a reference to an array of reals
    if xyInt
      xy = xyInt
      resolution = 1
    end
    
    if xy.is_a? Array
      x ||= xy[0]
      y ||= xy[1]
    end
    

    raise "printText expects a x coord. Missing -xy=>\#{array} or -x => 'num'" unless x
    raise "printText expects a y coord. Missing -xy=>\#{array} or -y => 'num'" unless y

    x = snap_int(x)
    y = snap_int(y)

    if !reflect || (reflect <= 0)
      reflect = 0
    else
      reflect = 1
      useSTRANS = true
    end
    raise "Invalid font, must be in 0..3" unless (0..3).include?(font)
    font = format('%02d', font)

    vertical
    top = arg['-top']
    middle = arg['-middle']
    bottom = arg['-bottom']
    vertical = if top
                 '00'
               elsif bottom
                 '10'
               else
                 '01'
               end ## middle
    horizontal
    left   = arg['-left']
    center = arg['-center']
    right  = arg['-right']
    horizontal = if left; '00'
                 elsif right; '10'
                 else; '01'
                 end ## center
    presString = '0' * 10
    presString += "#{font}#{vertical}#{horizontal}"

    #mag = arg['-mag']
    mag = if !mag || (mag <= 0)
            0
          else

            cleanFloatNum(mag)
          end
    #angle = arg['-angle']
    angle = if !angle

              -1; # not really... just means not specified

            else

              posAngle(angle)
            end
    printGds2Record(type: 'TEXT')
    printGds2Record(type: 'LAYER', data: layer)
    printGds2Record(type: 'TEXTTYPE', data: textType)
    printGds2Record(type: 'PRESENTATION', data: presString) if font || top || middle || bottom || bottom || left || center || right
    if useSTRANS
      data = reflect + '0' * 15; ## 16 'bit' string
      printGds2Record(type: 'STRANS', data: data)
    end
    printGds2Record(type: 'MAG', data: mag) if mag
    printGds2Record(type: 'ANGLE', data: angle) if angle >= 0
    printGds2Record(type: 'XY', data: [x, y])
    printGds2Record(type: 'STRING', data: string)
    printGds2Record(type: 'ENDEL')
  end
  ############################################################################

  # = Low Level Generic Write Methods
  #

  ############################################################################

  # ==  saveGds2Record() - low level method to create a gds2 record given record type
  #   and data (if required). Data of more than one item should be given as a list.
  #
  #   NOTE: THIS ONLY USES GDS2 OBJECT TO GET RESOLUTION
  #
  #   usage:
  #     saveGds2Record(
  #             type: string,
  #             -data=>data_If_Needed, ##optional for some types
  #             -scale=>#.#,           ##optional number to scale data to. I.E -scale=>0.5 #default is NOT to scale
  #             -snap=>#.#,            ##optional number to snap data to I.E. -snap=>0.005 #default is 1 resolution unit, typically 0.001
  #     );
  #
  #   examples:
  #     gds2File = GDS2.new(-fileName => ">$fileName");
#     record = gds2File.saveGds2Record(type: 'header',-data=>3);
  #     gds2FileOut.printGds2Record(type: 'record',-data=>$record);
  #
  #

  def saveGds2Record(data: nil, asciiData: nil, scale: 1, snap: nil)
    record = ''

    if type
      type = type.upcase
    else
      raise "saveGds2Record expects a type name. Missing type: 'name'"
    end

    saveEnd = $OUTPUT_RECORD_SEPARATOR
    $\ = ''

    dataString = asciiData
    raise 'saveGds2Record can not handle both -data and -asciiData options' if asciiData && data

    data = ''
    if type == 'RECORD' ## special case...
      return data[0]
    else

      numDataElements = 0
      resolution = @Resolution
      
      if scale <= 0

        raise "saveGds2Record expects a positive scale -scale => #{scale}"
      end

      snap = arg['-snap']
      snap = if !snap ## default is one resolution unit

               1

             else

               snap * resolution; ## i.e. 0.001 -> 1
             end
      if snap < 1

        raise "saveGds2Record expects a snap >= 1/resolution -snap => #{snap}"
      end

      if (data[0]) && (data[0] != '')

        data = data[0]
        numDataElements = @data
        if numDataElements ## passed in anonymous array

          data = @data; ## deref

        else

          numDataElements = data
        end
      end

      recordDataType = recordtypedata[type]
      if asciiData
        dataString = asciiData.strip
        dataString.gsub!(/\s+/, ' ') if dataString !~ /'/; ## don't compress spaces in strings...
        dataString.sub!(/'$/, ''); # 'for strings
        dataString.sub!(/^'/, ''); # 'for strings
        if (recordDataType == BIT_ARRAY) || (recordDataType == ASCII_STRING)
          data = dataString
        else

          dataString.gsub!(/\s*[\s,;:\/\\]+\s*/, ' '); ## incase commas etc... (non-std) were added by hand
          data = split(' ', dataString)
          numDataElements = data
          if recordDataType == INTEGER_4

            xyTmp = []
            (0..numDataElements - 1).each do |i|
              xyTmp << snap_int(data[i])
            end
            data = xyTmp
          end
        end
    end
    
      byte = nil 
      length = 0
      if recordDataType == BIT_ARRAY
        length = 2
      elsif recordDataType == INTEGER_2
        length = 2 * numDataElements
      elsif recordDataType == INTEGER_4
        length = 4 * numDataElements
      elsif recordDataType == REAL_8
        length = 8 * numDataElements
      elsif recordDataType == ASCII_STRING
        slen = data.length
        length = slen + (slen % 2); ## needs to be an even number
      end

      recordLength = [(length + 4)].pack 'S' # 1 2 bytes for length 3rd for recordType 4th for dataType
      record += recordLength
      recordType = RECORDTYPENUMBERS[type].pack 'C'
      record += recordType

      dataType = RECORDTYPEDATA[type].pack 'C'
      record += dataType

      if recordDataType == BIT_ARRAY      ## bit array

        bitLength = length * 8
        record += data.pack("B#{bitLength}")

      elsif recordDataType == INTEGER_2   ## 2 byte signed integer

        data.each do |num|
          record += [num].pack('s')
        end

      elsif recordDataType == INTEGER_4   ## 4 byte signed integer

        data.each do |num|
          num = scaleNum(num, scale) if scale != 1
          num = snapNum(num, snap) if snap != 1
          record += pack('i', num)
        end

      elsif recordDataType == REAL_8 ## 8 byte real

        data.each do |num|
          real = num
          negative = false
          if num < 0.0
            negative = true
            real = 0 - num
          end

          exponent = 0
          while real >= 1.0
            exponent += 1
            real = (real / 16.0)
          end

          if real != 0

            while real < 0.0625

              --exponent
              real = (real * 16.0)
            end
          end

          exponent += negative ? 192 : 64
          record += [exponent].pack('C')

          (1..7).each do |_i|
            byte = if real >= 0
                     int((real * 256.0) + GDS2::g_epsilon)
                   else
                     int((real * 256.0) - GDS2::g_epsilon)
                   end
            record += [byte].pack('C')
            real = real * 256.0 - (byte + 0.0)
          end
        end

      elsif recordDataType == ASCII_STRING ## ascii string (null padded)
        record += data.pack("a#{length}")
      end
    end
    $\ = saveEnd
    record
  end
  ############################################################################

  # ==  printGds2Record() - low level method to print a gds2 record given record type
  #   and data (if required). Data of more than one item should be given as a list.
  #
  #   usage:
  #     printGds2Record(
  #             type: string,
  #             -data=>data_If_Needed, ##optional for some types
  #             -scale=>#.#,           ##optional number to scale data to. I.E -scale=>0.5 #default is NOT to scale
  #             -snap=>#.#,            ##optional number to snap data to I.E. -snap=>0.005 #default is 1 resolution unit, typically 0.001
  #     );
  #
  #   examples:
  #     gds2File = new GDS2(-fileName => ">$fileName");
  #
  #     gds2File.printGds2Record(type: 'header',-data=>3);
  #     gds2File.printGds2Record(type: 'bgnlib',-data=>[99,12,1,22,33,0,99,12,1,22,33,9]);
  #     gds2File.printGds2Record(type: 'libname',-data=>"testlib");
  #     gds2File.printGds2Record(type: 'units',-data=>[0.001, 1e-9]);
  #     gds2File.printGds2Record(type: 'bgnstr',-data=>[99,12,1,22,33,0,99,12,1,22,33,9]);
  #     ...
  #     gds2File.printGds2Record(type: 'endstr');
  #     gds2File.printGds2Record(type: 'endlib');
  #
  #   Note: the special record type of 'record' can be used to copy a complete record
  #   just read in:
  #     while ($record = gds2FileIn.readGds2Record())
  #     {
  #         gds2FileOut.printGds2Record(type: 'record',-data=>$record);
  #     }
  #

  def printGds2Record(type: nil, data: nil, asciiData: nil, snap: nil, scale: 1)
    p [:prec, type, data]
    raise "printGds2Record expects a type name. Missing type: 'name'" unless type
    type = type.upcase

    dataString = asciiData
    raise 'printGds2Record can not handle both data: and asciiData: options' if asciiData && data

    fh = @FileHandle
    saveEnd = $OUTPUT_RECORD_SEPARATOR
    $\ = ''

    data = [] unless data
    recordLength = nil ## 1st 2 bytes for length 3rd for recordType 4th for dataType
    if type == 'RECORD' ## special case...
      
      if GDS2.isLittleEndian

        length = data[0][0..1]
        recordLength = length.unpack('v').first
        @BytesDone += recordLength
        length = length.reverse
        fh.print(length)

        recordType = data[0][2]
        fh.print(recordType)
        recordType = recordType.unpack('C').first
        type = RECORDTYPESTRINGS[recordType]; ## will use code below.....

        dataType = data[0][3]
        fh.print(dataType)
        dataType = dataType.unpack('C').first
        if recordLength > 4

          lengthLeft = recordLength - 4; ## length left
          recordDataType = recordtypedata[type]

          if (recordDataType == INTEGER_2) || (recordDataType == BIT_ARRAY)

            binData = data[0].unpack('b*')
            intData = substr(binData, 32); # skip 1st 4 bytes (length, recordType dataType)

            byteInt2String = nil
            byte2 = nil
            (0..lengthLeft / 2 - 1).each do |_i|
              byteInt2String = reverse(substr(intData, 0, 16, ''))
              byte2 = pack 'B16', reverse(byteInt2String)
              fh.print(byte2)
            end

          elsif recordDataType == INTEGER_4

            binData = unpack 'b*', data[0]
            intData = substr(binData, 32); # skip 1st 4 bytes (length, recordType dataType)
            # (byteInt4String,byte4)
            (0..lengthLeft / 4 - 1).each do |_i|
              byteInt4String = reverse(substr(intData, 0, 32, ''))
              byte4 = pack 'B32', reverse(byteInt4String)
              fh.print byte4
            end

          elsif recordDataType == REAL_8

            binData = unpack 'b*', data[0]
            realData = substr(binData, 32); # skip 1st 4 bytes (length, recordType dataType)
            # (bit64String,mantissa,byteString,byte)
            (0..lengthLeft / 8 - 1).each do |i|
              bit64String = substr(realData, (i * 64), 64)
              fh.print(pack('b8', bit64String))
              mantissa = substr(bit64String, 8, 56)
              (0..6).each do |j|
                byteString = substr(mantissa, (j * 8), 8)
                byte = pack 'b8', byteString
                fh.print(byte)
              end
            end

          elsif recordDataType == ASCII_STRING ## ascii string (null padded)
            
            fh.print pack("a#{lengthLeft}", substr(data[0], 4))

          elsif recordDataType == REAL_4 ## 4 byte real

            raise NotImplementedError, '4-byte reals are not supported'
          end
        end

      else

        fh.print(data[0])
        recordLength = data[0].length
        @BytesDone += recordLength
      end

    else # if ($type ne 'RECORD')

      numDataElements = 0
      resolution = @Resolution
      uUnits = @UUnits

      raise "printGds2Record expects a positive scale -scale => #{scale}" if scale <= 0
      
      snap = if !snap ## default is one resolution unit
               1
             else
               int((snap * resolution) + GDS2::g_epsilon); ## i.e. 0.001 -> 1
             end

      raise "printGds2Record expects a snap >= 1/resolution -snap => #{snap}" if snap < 1

      unless data.is_a? Array
        data = [data]
      end
      
      #  data = data[0]
      numDataElements = data.size
      #  if numDataElements ## passed in anonymous array
      #    data = @data; ## deref
      #  else
      #    numDataElements = data
      #  end
      #end

      recordDataType = RECORDTYPEDATA[type]

      if asciiData
        dataString = asciiData.strip
        dataString.gsub!(/\s+/, ' ') if dataString !~ /'/; ## don't compress spaces in strings...
        dataString.sub!(/'$/, ''); # '# for strings
        dataString.sub!(/^'/, ''); # '# for strings
        if (recordDataType == BIT_ARRAY) || (recordDataType == ASCII_STRING)
          data = dataString
        else

          dataString.gsub!(/\s*[\s,;:\/\\]+\s*/, ' '); ## in case commas etc... (non-std) were added by hand
          data = dataString.split(' ')
          numDataElements = data
          if recordDataType == INTEGER_4

            xyTmp = []
            (0..numDataElements - 1).each do |i| ## e.g. 3.4 in -> 3400 out
              xyTmp << snap_int(data[i])
            end
            data = xyTmp
          end
        end
      end

      byte = nil
      length = 0
      if recordDataType == BIT_ARRAY
        length = 2
      elsif recordDataType == INTEGER_2
        length = 2 * numDataElements
      elsif recordDataType == INTEGER_4
        length = 4 * numDataElements
      elsif recordDataType == REAL_8
        length = 8 * numDataElements
      elsif recordDataType == ASCII_STRING
        data = data.first
        slen = data.length
        length = slen + (slen % 2); ## needs to be an even number
        #p [:strlencompute, data, slen, length]
      end
      @BytesDone += length
      #p [:datax, data, numDataElements, recordDataType]
      
      if GDS2.isLittleEndian
        recordLength = [(length + 4)].pack 'v'
        recordLength = recordLength.reverse
      else
        recordLength = [(length + 4)].pack 'S'
      end
      fh.print(recordLength)

      recordType = [RECORDTYPENUMBERS[type]].pack 'C'
      recordType = recordType.reverse if GDS2.isLittleEndian
      fh.print(recordType)

      dataType = [RECORDTYPEDATA[type]].pack 'C'
      dataType = dataType.reverse if GDS2.isLittleEndian
      fh.print(dataType)
      #p [:xx, data]
      if recordDataType == BIT_ARRAY      ## bit array
        bitLength = length * 8
        value = data.pack("B#{bitLength}")
        fh.print(value)

      elsif recordDataType == INTEGER_2   ## 2 byte signed integer
        p data
        # value
        data.each do |num|
          value = [num].pack('s')
          value = value.reverse if GDS2.isLittleEndian
          fh.print(value)
        end

      elsif recordDataType == INTEGER_4 ## 4 byte signed integer

        # value
        data.each do |num|
          num = scaleNum(num, scale) if scale != 1
          num = snapNum(num, snap) if snap != 1
          value = [num].pack('i')
          value = value.reverse if GDS2.isLittleEndian
          fh.print(value)
        end

      elsif recordDataType == REAL_8 ## 8 byte real

        # (real,negative,exponent,value)
        p [:realdata, data]
        data.each do |num|
          num = num.to_f
          real = num
          negative = false
          if num < 0.0
            negative = true
            real = 0.0 - num
          end

          exponent = 0
          while real >= 1.0
            exponent += 1
            real = (real / 16.0)
          end

          if real != 0
            while real < 0.0625
              --exponent
              real = (real * 16.0)
            end
          end

          exponent +=  negative ? 192 : 64
          value = [exponent].pack('C')
          value = value.reverse if GDS2.isLittleEndian
          fh.print(value)
          dbgstr = [:exp, value.ord]
          (1..7).each do |i|
            byte = if real >= 0
                     (real * 256.0) + GDS2::g_epsilon
                   else
                     (real * 256.0) - GDS2::g_epsilon
                   end
            value = [byte.to_i].pack('C')
            value = value.reverse if GDS2.isLittleEndian
            fh.print(value)
            dbgstr << [i, value.ord, value, real]

            real = real * 256.0 - (byte + 0.0)
          end
          pp dbgstr
        end

      elsif recordDataType == ASCII_STRING ## ascii string (null padded)
        #p [:asciiData, data, [data].pack("a*"), length]
        fh.print([data].pack("a#{length}"))
      end
    end
    $\ = saveEnd
  end

############################################################################

  # == printRecord - prints a record just read
  #
  #   usage:
  #     gds2File.printRecord(
  #                   -data => $record
  #                 );
  #

  def printRecord(*arg)
    record = arg['-data']
    unless record

      raise "printGds2Record expects a data record. Missing -data => \#{record}"
    end
    type = arg['-type']
    if  type

      raise 'printRecord does not take -type. Perhaps you meant to use printGds2Record?'
    end
    printGds2Record(type: 'record', data: record)
  end
  ############################################################################

  ############################################################################

  # = Low Level Generic Read Methods
  #

  ############################################################################

  # == readGds2Record - reads record header and data section
  #
  #   usage:
  #   while (gds2File.readGds2Record)
  #   {
  #       if (gds2File.returnRecordTypeString eq 'LAYER')
  #       {
  #           $layersFound[gds2File.layer] = 1;
  #       }
  #   }
  #

  def readGds2Record
    return false if @EOLIB
    readGds2RecordHeader
    readGds2RecordData
    @INHEADER = false
    @INDATA   = true; ## actually just done w/ it
    @Record
  end
  ############################################################################

  # == readGds2RecordHeader - only reads gds2 record header section (2 bytes)
  #
  #   slightly faster if you just want a certain thing...
  #   usage:
  #   while (gds2File.readGds2RecordHeader)
  #   {
  #       if (gds2File.returnRecordTypeString eq 'LAYER')
  #       {
  #           gds2File.readGds2RecordData;
  #           $layersFound[gds2File.returnLayer] = 1;
  #       }
  #   }
  #

  def readGds2RecordHeader
    # print "INFO: READING HEADER\n";
    skipGds2RecordData if !@INDATA && (@INHEADER != UNKNOWN); # need to read record data before header unless 1st time
    @Record = ''
    @RecordType = UNKNOWN
    @INHEADER = true ## will actually be just just done with it by the time we can check this ...
    @INDATA   = false
    return false if @EOLIB ## no sense reading null padding..

    buffer = ''
    return false unless buffer = @FileHandle.read(4)

    # if (read($self.{'FileHandle'},$data,2)) ### length
    data = buffer[0..1]
    begin
      data = data.reverse if GDS2.isLittleEndian
      @Record = data
      @Length = data.unpack('S').first
      @BytesDone += @Length
    end

    # if (read($self.{'FileHandle'},$data,1)) ## record type
    data = buffer[2]
    begin
      data = data.reverse if GDS2.isLittleEndian
      @Record += data
      @RecordType = data.unpack('C').first
      @EOLIB = true if @RecordType == ENDLIB

      if @UsingPrettyPrint
        putStrSpace('')   if @RecordType == ENDSTR
        putStrSpace('  ') if @RecordType == BGNSTR
        putElmSpace('  ') if (@RecordType == TEXT) || (@RecordType == PATH) ||
                              (@RecordType == BOUNDARY) || (@RecordType == SREF) ||
                              (@RecordType == AREF)
        if @RecordType == ENDEL

          putElmSpace('')
          @InTxt = false
          @InBoundary = false
        end
        @InTxt = true if @RecordType == TEXT
        @InBoundary = true if @RecordType == BOUNDARY
        @DateFld = 0 if (@RecordType == LIBNAME) || (@RecordType == STRNAME)
        @DateFld = 1 if (@RecordType == BGNLIB) || (@RecordType == BGNSTR)
      end
    end

    # if (read($self.{'FileHandle'},$data,1)) ## data type
    data = buffer[3]
    begin
      data = data.reverse if GDS2.isLittleEndian
      @Record += data
      @DataType = data.unpack('C').first
    end
    # printf("P:Length=%-5d RecordType=%-2d DataType=%-2d DataIndex=%-2d\n",@Length,@RecordType,@DataType,@DataIndex); ##DEBUG
    # print "INFO: DONE READING HEADER\n";
    true
  end
  ############################################################################

  # == readGds2RecordData - only reads record data section
  #
  #   slightly faster if you just want a certain thing...
  #   usage:
  #   while (gds2File.readGds2RecordHeader)
  #   {
  #       if (gds2File.returnRecordTypeString eq 'LAYER')
  #       {
  #           gds2File.readGds2RecordData;
  #           $layersFound[gds2File.returnLayer] = 1;
  #       }
  #   }
  #

  def readGds2RecordData
    readGds2RecordHeader if @INHEADER != true; # program did not read HEADER - needs to...
    return @Record if @DataType == NO_REC_DATA; # no sense going on...
    @INHEADER = false; # not in HEADER - need to read HEADER next time around...
    @INDATA   = true;  # rather in DATA - actually will be at the end of data by the time we test this...
    # @RecordData = ''
    @RecordData = []
    @CurrentDataList = ''
    bytesLeft = @Length - 4; ## 4 should have been just read by readGds2RecordHeader
    # data
    if @DataType == BIT_ARRAY ## bit array

      @DataIndex = 0
      data = @FileHandle.read(bytesLeft)
      data = data.reverse if GDS2.isLittleEndian
      bitsLeft = bytesLeft * 8
      @Record += data
      @RecordData[0] = data.unpack "B#{bitsLeft}"
      @CurrentDataList = (@RecordData[0])

    elsif @DataType == INTEGER_2   ## 2 byte signed integer

      tmpListString = ''
      i = 0
      while bytesLeft > 0
        data = @FileHandle.read(2)
        data = data.reverse if GDS2.isLittleEndian
        @Record += data
        @RecordData[i] = data.unpack('s').first
        tmpListString += ','
        tmpListString += @RecordData[i].to_s
        i += 1
        bytesLeft -= 2
      end
      @DataIndex = i - 1
      @CurrentDataList = tmpListString

    elsif @DataType == INTEGER_4   ## 4 byte signed integer

      tmpListString = ''
      i = 0
      buffer = @FileHandle.read(bytesLeft); ## try fewer reads
      0.step(bytesLeft - 1, 4) do |start|
        data = buffer[start..start + 3]
        data = data.reverse if GDS2.isLittleEndian
        @Record += data
        @RecordData[i] = data.unpack('i').first
        tmpListString += ','
        tmpListString += @RecordData[i].to_s
        i += 1
        # p [@RecordData, start]
      end

      @DataIndex = i - 1
      @CurrentDataList = tmpListString

    elsif @DataType == REAL_4   ## 4 byte real

      raise NotImplementedError, '4-byte reals are not supported'

    elsif @DataType == REAL_8   ## 8 byte real - UNITS, MAG, ANGLE

      resolution = @Resolution
      tmpListString = ''
      i = 0
      # (negative,exponent,mantdata,byteString,byte,mantissa,real)
      while  bytesLeft > 0

        data = @FileHandle.read(1); ## sign bit and 7 exponent bits
        @Record += data
        negative = data.unpack1('B').to_i ## sign bit
        exponent = data.unpack1('C')
        #p [:exp, data.ord, negative, exponent]
        exponent -= negative.zero? ? 64 : 192
        data = @FileHandle.read(7) ## mantissa bits
        mantdata = data.unpack1('b*')
        #p [:exp1, negative, exponent, mantdata]
        @Record += data
        mantissa = 0.0
        (0..6).each do |j|
          byteString = mantdata[(0 + j * 8)..(7 + j * 8)]
          byte = [byteString].pack('b*').unpack1('C')
          mantissa += byte / (256.0**(j + 1))
          #p [:exp2, byte, byteString, mantissa]
        end
        real = mantissa * (16**exponent)
        real = (0 - real) if negative != 0
        #p [:exp3, real, mantissa]
        if RECORDTYPESTRINGS[@RecordType] == 'UNITS'
          if @UUnits == -1.0
            @UUnits = real
          elsif @DBUnits == -1.0
            @DBUnits = real
          end
        else

          ### this works because UUnits and DBUnits are 1st reals in GDS2 file
          real = ((real + (@UUnits / resolution)) / @UUnits).to_i * @UUnits if @UUnits != 0; ## "rounds" off
        end
        @RecordData[i] = real.to_i
        tmpListString += ','
        tmpListString += @RecordData[i].to_s
        i += 1
        bytesLeft -= 8
      end
      @DataIndex = i - 1
      @CurrentDataList = tmpListString

    elsif @DataType == ASCII_STRING   ## ascii string (null padded)
      @DataIndex = 0
      data = @FileHandle.read(bytesLeft)
      @Record += data
      @RecordData[0] = data.unpack("a#{bytesLeft}").first
      @RecordData[0].gsub!(/\0/, ''); ## take off ending nulls
      @CurrentDataList = @RecordData[0]
    end
    true
  end
  ############################################################################
  # = Low Level Generic Evaluation Methods
  #
  ############################################################################
  # == returnRecordType - returns current (read) record type as integer
  #
  #   usage:
  #   if (gds2File.returnRecordType == 6)
  #     puts "found STRNAME";
  #   end
  #
  def returnRecordType
    @RecordType
  end

  ############################################################################
  # == returnRecordTypeString - returns current (read) record type as string
  #
  #   usage:
  #   if (gds2File.returnRecordTypeString eq 'LAYER')
  #       code goes here...
  #   end
  #
  def returnRecordTypeString
    RECORDTYPESTRINGS[@RecordType]
  end

  ############################################################################
  # == returnRecordAsString - returns current (read) record as a string
  #
  #   usage:
  #   while (gds2File.readGds2Record)
  #       print gds2File.returnRecordAsString(compact: true);
  #   end
  #

  def returnRecordAsString(compact: false)
    string = ''
    @UsingPrettyPrint = true
    inText = @InTxt
    inBoundary = @InBoundary
    dateFld = @DateFld
    unless compact
      string += getStrSpace if @RecordType != BGNSTR
      string += getElmSpace unless
          (@RecordType == BOUNDARY) ||
          (@RecordType == PATH) ||
          (@RecordType == TEXT) ||
          (@RecordType == SREF) ||
          (@RecordType == AREF)

    end

    recordType = RECORDTYPESTRINGS[@RecordType]
    # p [:recRecordAsStr, @RecordType, recordType, @RecordData, @DataIndex]
    string += if compact
                # p [:xxx, @RecordType, COMPACTRECORDTYPESTRINGS[@RecordType]]
                COMPACTRECORDTYPESTRINGS[@RecordType]
              else
                recordType
              end
    i = 0
    while i <= @DataIndex
      # puts "INFO: #{@DataIndex} #{@DataType}"
      if @DataType == BIT_ARRAY

        bitString = @RecordData[i]
        if GDS2.isLittleEndian

          bitString =~ /(........)(........)/
          bitString = "#{Regexp.last_match(2)}#{Regexp.last_match(1)}"
        end
        if compact

          string += ' fx' if bitString =~ /^1/
          if inText && (@RecordType != STRANS)

            string += ' f'
            string += '0' if bitString =~ /00....$/
            string += '1' if bitString =~ /01....$/
            string += '2' if bitString =~ /10....$/
            string += '3' if bitString =~ /11....$/
            string += ' t' if bitString =~ /00..$/
            string += ' m' if bitString =~ /01..$/
            string += ' b' if bitString =~ /10..$/
            string += 'l' if bitString =~ /00$/
            string += 'c' if bitString =~ /01$/
            string += 'r' if bitString =~ /10$/
          end

        else

          string += '  ' + bitString
        end

      elsif @DataType == INTEGER_2

        if compact
          if dateFld
            num = @RecordData[i]
            if dateFld =~ /^[17]$/
              if dateFld == '1'
                string += if recordType == 'BGNLIB'
                            'm='
                          else
                            'c='
                          end
              elsif dateFld == '7'
                string += if recordType == 'BGNLIB'
                            ' a='
                          else
                            ' m='
                          end
              end
              num += 1900 if num < 1900
            end
            num = format('%02d', num)
            string += '-' if dateFld =~ /^[2389]/
            string += ':' if dateFld =~ /^[56]/
            string += ':' if dateFld =~ /^1[12]/
            string += ' ' if (dateFld == '4') || (dateFld == '10')
            string += num
          else
            string += ' ' unless string =~ / (a|m|pt|dt|tt)$/i
            string += @RecordData[i]
          end

        else
          string += '  '
          string += @RecordData[i].to_s
        end

        if recordType == 'UNITS'
          string.sub!(/(\d)\.e/, '\\1e'); ## perl on Cygwin prints "1.e-9" others "1e-9"
          string.sub!(/(\d)e\-0+/, '\\1e-'); ## different perls print 1e-9 1e-09 1e-009 etc... standardize to 1e-9
        end

      elsif @DataType == INTEGER_4

        if compact
          string += ' ' if i
        else
          string += '  '
        end

        string += cleanFloatNum(@RecordData[i] * @UUnits).to_s
        if compact && i && (i == @RecordData.size)
          string.sub!(/ +[\d\.\-]+ +[\d\.\-]+$/, '') if inBoundary; # remove last point
          string += ')'
        end

      elsif @DataType == REAL_8

        if compact
          string += ' ' unless string =~ / (a|m|pt|dt|tt)$/i
        else
          string += '  '
        end
        num = @RecordData[i]

        num = if num =~ /e/i
                cleanExpNum(num)
              else
                cleanFloatNum(num)
              end
        string += num.to_s

        if recordType == 'UNITS'
          string.sub!(/(\d)\.e/, '\\1e'); ## perl on Cygwin prints "1.e-9" others "1e-9"
          string.sub!(/(\d)e\-0+/, '\\1e-'); ## different perls print 1e-9 1e-09 1e-009 etc... standardize to shorter 1e-9
        end

      elsif @DataType == ASCII_STRING
        string += ' ' unless compact
        string += " '" + @RecordData[i] + "'"
      end

      i += 1
      dateFld += 1 if dateFld
    end

    if compact
      g_gdtstring = '' # G_GDTSTRING
      g_gdtstring += string
      if (g_gdtstring =~ /}$/ || g_gdtstring =~ /^(gds2|lib|m).*\d$/) || (g_gdtstring =~ /^cell.*'$/)

        string = "#{g_gdtstring}\n"
        string.sub!(/{ /, '{'); # a little more compact
        string.gsub!(/(dt0|pt0|tt0|m1|w0|f0) /, ''); # these are all default in true GDT format
        # g_gdtstring = ""

      else

        string = ''
      end
    end

    string
  end
  ############################################################################

  # == returnXyAsArray - returns current (read) XY record as an array
  #
  #   usage:
  #     gds2File.returnXyAsArray(
  #                     -asInteger => 0|1    ## (optional) default is true. Return integer
  #                                          ## array or if false return array of reals.
  #                     -withClosure => 0|1  ## (optional) default is true. Whether to
  #                                          ##return a rectangle with 5 or 4 points.
  #                );
  #
  #   example:
  #   while (gds2File.readGds2Record)
  #       xy = gds2File.returnXyAsArray if gds2File.isXy;
  #   end
  #

  def returnXyAsArray(asInteger: true, withClosure: true)
    xys = []
    if isXy
      i = 0
      stopPoint = @DataIndex
      if withClosure
        return @RecordData if asInteger
      else
        stopPoint -= 2
      end
      num = 0
      while i <= stopPoint
        num = if asInteger
                @RecordData[i]
              else
                cleanFloatNum(@RecordData[i] * @UUnits)
              end
        xys << num
        i += 1
      end
    end
    xys
  end
  ############################################################################

  # == returnRecordAsPerl - returns current (read) record as a perl command to facilitate the creation of parameterized gds2 data with perl.
  #
  #   usage:
  #   #!/usr/local/bin/perl
  #   require 'gds2'
  #   gds2File = new GDS2(-fileName=>"test.gds");
  #   while (gds2File.readGds2Record)
  #   {
  #       print gds2File.returnRecordAsPerl;
  #   }
  #

  def returnRecordAsPerl (*arg)
    gds2File = arg['-gds2File']
    gds2File ||= 'gds2File'

    pgr = arg['-printGds2Record']
    pgr ||= 'printGds2Record'

    string = ''
    @UsingPrettyPrint = true
    string += getStrSpace if @RecordType != BGNSTR
    string += getElmSpace unless
        (@RecordType == TEXT) ||
        (@RecordType == PATH) ||
        (@RecordType == BOUNDARY) ||
        (@RecordType == SREF) ||
        (@RecordType == AREF)

    if
      (@RecordType == TEXT) ||
      (@RecordType == PATH) ||
      (@RecordType == BOUNDARY) ||
      (@RecordType == SREF) ||
      (@RecordType == AREF) ||
      (@RecordType == ENDEL) ||
      (@RecordType == ENDSTR) ||
      (@RecordType == ENDLIB)

      string += gds2File + '.' + pgr + '(type: ' + "'" + recordtypestrings[@RecordType] + "'" + ');'

    else

      string += gds2File + '.' + pgr + '(type: ' + "'" + recordtypestrings[@RecordType] + "',data: "
      i = 0
      maxi = @DataIndex
      string += '[' if maxi >= 1
      while i <= maxi

        if @DataType == BIT_ARRAY

          bitString = @RecordData[i]
          if GDS2.isLittleEndian

            bitString =~ /(........)(........)/
            bitString = "#{Regexp.last_match(2)}#{Regexp.last_match(1)}"
          end
          string += "'#{bitString}'"

        elsif @DataType == INTEGER_2

          string += @RecordData[i]

        elsif @DataType == INTEGER_4

          string += @RecordData[i]

        elsif @DataType == REAL_8

          string += @RecordData[i]

        elsif @DataType == ASCII_STRING

          string += "'" + @RecordData[i] + "'"
        end
        string += ', ' if i < maxi
        i += 1
      end
      string += ']' if maxi >= 1
      string += ');'
    end
    string
  end
  ############################################################################

  # = Low Level Specific Write Methods
  #

  ############################################################################

  # == printAngle - prints ANGLE record
  #
  #   usage:
  #     gds2File.printAngle(num: #.#);
  #

  def printAngle(num: nil)
    printGds2Record(type: 'ANGLE', data: posAngle(num)) if num
  end
  ############################################################################

  # == printAttrtable - prints ATTRTABLE record
  #
  #   usage:
  #     gds2File.printAttrtable(string: $string);
  #

  def printAttrtable(string: nil)
    raise "printAttrtable expects a string. Missing string: 'text'" unless string
    printGds2Record(type: 'ATTRTABLE', data: string)
  end
  ############################################################################

  # == printBgnextn - prints BGNEXTN record
  #
  #   usage:
  #     gds2File.printBgnextn(num: #.#);
  #

  def printBgnextn(num: nil)
    raise 'printBgnextn expects a extension number. Missing num: #.#' unless num
    printGds2Record(type: 'BGNEXTN', data: snap_int(num))
  end

  ############################################################################
  # == printBgnlib - prints BGNLIB record
  #
  #   usage:
  #     gds2File.printBgnlib( isoDate: true|false ## (optional) use ISO 4 digit date 2001 vs 101
  #                          )
  #

  def printBgnlib(isoDate = false, *_arg)
    (sec, min, hour, mday, mon, year, wday, yday, isdst) = localtime(time)
    mon += 1
    year += 1900 if isoDate; ## Cadence likes year left "as is". GDS format supports year number up to 65535 -- 101 vs 2001
    printGds2Record(type: 'BGNLIB', data: [year, mon, mday, hour, min, sec, year, mon, mday, hour, min, sec])
  end
  ############################################################################

  # == printBox - prints BOX record
  #
  #   usage:
  #     gds2File.printBox;
  #

  def printBox
    printGds2Record(type: 'BOX')
  end
  ############################################################################

  # == printBoxtype - prints BOXTYPE record
  #
  #   usage:
  #     gds2File.printBoxtype(-num=>#);
  #

  def printBoxtype(num: nil)
    raise 'printBoxtype expects a number. Missing num: #' unless num
    printGds2Record(type: 'BOXTYPE', data: num)
  end
  ############################################################################

  # == printColrow - prints COLROW record
  #
  #   usage:
  #     gds2File.printBoxtype(-columns=>#, -rows=>#);
  #

  def printColrow(columns: 1, rows: 1)
    printGds2Record(type: 'COLROW', data: [columns.to_i, rows.to_i])
  end
  ############################################################################

  # == printDatatype - prints DATATYPE record
  #
  #   usage:
  #     gds2File.printDatatype(-num=>#);
  #

  def printDatatype(num: 0)
    printGds2Record(type: 'DATATYPE', data: num)
  end
  ############################################################################

  def printEflags
    # self =shift
    raise 'EFLAGS type not supported'
  end
  ############################################################################

  # == printElkey - prints ELKEY record
  #
  #   usage:
  #     gds2File.printElkey(-num=>#);
  #

  def printElkey(num: nil)
    raise 'printElkey expects a number. Missing num: #.#' unless num
    printGds2Record(type: 'ELKEY', data: num)
  end
  ############################################################################

  # == printEndel - closes an element definition
  #

  def printEndel
    printGds2Record(type: 'ENDEL')
  end
  ############################################################################

  # == printEndextn - prints path end extension record
  #
  #   usage:
  #     gds2File printEndextn.(-num=>#.#);
  #

  def printEndextn(num: nil)
    raise 'printEndextn expects a extension number. Missing num: #.#' unless num
    printGds2Record(type: 'ENDEXTN', data: snap_int(num))
  end
  ############################################################################

  # == printEndlib - closes a library definition
  #

  def printEndlib
    printGds2Record(type: 'ENDLIB')
  end
  ############################################################################
  # == printEndstr - closes a structure definition
  def printEndstr
    printGds2Record(type: 'ENDSTR')
  end
  ############################################################################
  # == printEndmasks - prints a ENDMASKS
  def printEndmasks
    printGds2Record(type: 'ENDMASKS')
  end
  ############################################################################

  # == printFonts - prints a FONTS record
  #
  #   usage:
  #     gds2File.printFonts(string: 'names_of_font_files');
  #

  def printFonts(string: nil)
    raise "printFonts expects a string. Missing string: 'text'" unless string
    printGds2Record(type: 'FONTS', data: string)
  end
  ############################################################################

  def printFormat(num: nil)
    raise 'printFormat expects a number. Missing num: #.#' unless num
    printGds2Record(type: 'FORMAT', data: num)
  end
  ############################################################################

  def printGenerations
    printGds2Record(type: 'GENERATIONS')
  end
  ############################################################################
  # == printHeader - Prints a rev 3 header
  #
  #   usage:
  #     gds2File.printHeader(
  #                   num: #  ## optional, defaults to 3. valid revs are 0,3,4,5,and 600
  #                 );
  #
  VALID_REVISIONS = [0, 3, 4, 5, 600]
  def printHeader(num: 3)
    raise "Num must be one of #{VALID_REVISIONS}" unless VALID_REVISIONS.include?(num)
    printGds2Record(type: 'HEADER', data: num)
  end

  ############################################################################
  # == printLayer - prints a LAYER number
  #
  #   usage:
  #     gds2File.printLayer(
  #                   num: #  ## optional, defaults to 0.
  #                 );
  #
  def printLayer(num: 0)
    printGds2Record(type: 'LAYER', data: layer)
  end

  ############################################################################
  def printLibdirsize
    printGds2Record(type: 'LIBDIRSIZE')
  end

  ############################################################################
  # == printLibname - Prints library name
  #
  #   usage:
  #     printLibname(-name=>$name);
  #
  def printLibname(name: nil)
    raise "printLibname expects a library name. Missing name: 'name'"    unless name
    printGds2Record(type: 'LIBNAME', data: name)
  end

  ############################################################################
  def printLibsecur
    printGds2Record(type: 'LIBSECUR')
  end

  ############################################################################
  def printLinkkeys(num: nil)
    raise 'printLinkkeys expects a number. Missing num: #.#' unless num
    printGds2Record(type: 'LINKKEYS', data: num)
  end

  ############################################################################
  def printLinktype(*arg)
    num = arg['-num']
    raise 'printLinktype expects a number. Missing num: #.#' unless num
    printGds2Record(type: 'LINKTYPE', data: num)
  end

  ############################################################################
  # == printPathtype - prints a PATHTYPE number
  #
  #   usage:
  #     gds2File.printPathtype(
  #                   num: #  ## optional, defaults to 0.
  #                 );
  #

  def printPathtype(num: nil)
    pathType = num
    pathType ||= 0
    printGds2Record(type: 'PATHTYPE', data: pathType) if pathType
  end
  ############################################################################

  # == printMag - prints a MAG number
  #
  #   usage:
  #     gds2File.printMag(
  #                   num: #.#  ## optional, defaults to 0.0
  #                 );
  #

  def printMag(num: nil)
    mag = num
    mag = 0 if !mag || (mag <= 0)
    mag = cleanFloatNum(mag)
    printGds2Record(type: 'MAG', data: mag) if mag
  end

  ############################################################################
  def printMask(string: nil)
    raise "printMask expects a string. Missing string: 'text'" unless string
    printGds2Record(type: 'MASK', data: string)
  end

  ############################################################################
  def printNode
    printGds2Record(type: 'NODE')
  end

  ############################################################################
  # == printNodetype - prints a NODETYPE number
  #
  #   usage:
  #     gds2File.printNodetype(
  #                   num: #
  #                 );
  #
  def printNodetype (num: nil)
    raise 'printNodetype expects a number. Missing num: #' unless num
    printGds2Record(type: 'NODETYPE', data: num)
  end
  ############################################################################

  def printPlex (num: nil)
    raise 'printPlex expects a number. Missing num: #.#' unless num
    printGds2Record(type: 'PLEX', data: num)
  end
  ############################################################################

  # == printPresentation - prints a text presentation record
  #
  #   usage:
  #     gds2File.printPresentation(
  #                   -font => #,  ##optional, defaults to 0, valid numbers are 0-3
  #                   -top, ||-middle, || -bottom, ## vertical justification
  #                   -left, ||-center, || -right, ## horizontal justification
  #                 );
  #
  #   example:
  #     gds2File.printPresentation(font: 0,-top,-left);
  #

  def printPresentation(*arg)
    font = arg['-font']
    font = 0 if !font || (font < 0) || (font > 3)
    font = format('%02d', font)

    vertical
    top = arg['-top']
    middle = arg['-middle']
    bottom = arg['-bottom']
    vertical = if top; '00'
               elsif bottom; '10'
               else; '01'; end ## middle
    horizontal
    left   = arg['-left']
    center = arg['-center']
    right  = arg['-right']
    if    left   horizontal = '00'
    elsif right  horizontal = '10'
    else horizontal = '01'
    end ## center
    bitstring = '0' * 10
    bitstring += "#{font}#{vertical}#{horizontal}"
    printGds2Record(type: 'PRESENTATION', data: bitstring)
  end
  ############################################################################

  # == printPropattr - prints a property id number
  #
  #   usage:
  #     gds2File.printPropattr( num: # );
  #

  def printPropattr(num: nil)
    raise 'printPropattr expects a number. Missing num: #' unless num
    printGds2Record(type: 'PROPATTR', data: num)
  end
  ############################################################################

  # == printPropvalue - prints a property value string
  #
  #   usage:
  #     gds2File.printPropvalue( string: $string );
  #

  def printPropvalue(string: nil)
    raise "printPropvalue expects a string. Missing string: 'text'" unless string
    printGds2Record(type: 'PROPVALUE', data: string)
  end

  ############################################################################
  def printReflibs(string: nil)
    raise "printReflibs expects a string. Missing string: 'text'" unless string
    printGds2Record(type: 'REFLIBS', data: string)
  end
  ############################################################################

  def printReserved(num: nil)
    raise 'printReserved expects a number. Missing num: #.#' unless num
    printGds2Record(type: 'RESERVED', data: num)
  end
  ############################################################################

  # == printSname - prints a SNAME string
  #
  #   usage:
  #     gds2File.printSname( name: $cellName );
  #

  def printSname(name: nil)
    raise "printSname expects a cell name. Missing name: 'text'" unless name
    printGds2Record(type: 'SNAME', data: name)
  end
  ############################################################################

  def printSpacing
    raise NotImplementedError, 'SPACING type not supported'
  end
  ############################################################################

  def printSrfname
    printGds2Record(type: 'SRFNAME')
  end
  ############################################################################

  # == printStrans - prints a STRANS record
  #
  #   usage:
  #     gds2File.printStrans( -reflect );
  #

  def printStrans(*arg)
    reflect = arg['-reflect']
    reflect = if !reflect || (reflect <= 0)

                0

              else

                1
              end
    data = reflect + '0' * 15; ## 16 'bit' string
    printGds2Record(type: 'STRANS', data: data)
  end
  ############################################################################

  def printStrclass
    printGds2Record(type: 'STRCLASS')
  end
  ############################################################################

  # == printString - prints a STRING record
  #
  #   usage:
  #     gds2File.printSname( string: $text );
  #

  def printString (string: nil)
    raise "printString expects a string. Missing string: 'text'" unless string
    printGds2Record(type: 'STRING', data: string)
  end
  ############################################################################

  # == printStrname - prints a structure name string
  #
  #   usage:
  #     gds2File.printStrname( name: $cellName );
  #

  def printStrname(name: nil)
    raise "printStrname expects a structure name. Missing name: 'name'" unless name
    printGds2Record(type: 'STRNAME', data: name)
  end
  ############################################################################

  def printStrtype
    raise NotImplementedError, 'STRTYPE type not supported'
  end
  ############################################################################

  def printStyptable(string: nil)
    raise "printStyptable expects a string. Missing string: 'text'" unless string
    printGds2Record(type: 'STYPTABLE', data: string)
  end
  ############################################################################

  def printTapecode (num: nil)
    raise 'printTapecode expects a number. Missing num: #.#' unless num
    printGds2Record(type: 'TAPECODE', data: num)
  end
  ############################################################################

  def printTapenum (num: nil)
    raise 'printTapenum expects a number. Missing num: #.#' unless num
    printGds2Record(type: 'TAPENUM', data: num)
  end
  ############################################################################

  def printTextnode
    printGds2Record(type: 'TEXTNODE')
  end
  ############################################################################

  # == printTexttype - prints a text type number
  #
  #   usage:
  #     gds2File.printTexttype( num: # );
  #

  def printTexttype (num: nil)
    raise 'printTexttype expects a number. Missing num: #' unless num
    num = 0 if num < 0
    printGds2Record(type: 'TEXTTYPE', data: num)
  end
  ############################################################################

  def printUinteger
    raise NotImplementedError, 'UINTEGER type not supported'
  end
  ############################################################################

  # == printUnits - Prints units record.
  #
  #   options:
  #     -uUnit   => real number ## (optional) default is 0.001
  #     -dbUnit  => real number ## (optional) default is 1e-9
  #

  def printUnits(*arg)
    uUnit = arg['-uUnit']
    if !uUnit

      uUnit = 0.001

    else

      @Resolution = (1 / uUnit); ## default is 1000 - already set in new()
    end
    @UUnits = uUnit
    #################################################
    dbUnit = arg['-dbUnit']
    dbUnit ||= 1e-9
    @DBUnits = dbUnit
    #################################################

    printGds2Record(type: 'UNITS', data: [uUnit, dbUnit])
  end
  ############################################################################

  def printUstring
    raise NotImplementedError, 'USTRING type not supported'
  end
  ############################################################################

  # == printWidth - prints a width number
  #
  #   usage:
  #     gds2File.printWidth( num: # );
  #

  def printWidth(num: 0)
    width = num
    width = 0 if !width || width <= 0
    printGds2Record(type: 'WIDTH', data: width) if width
  end
  ############################################################################

  # == printXy - prints an XY array
  #
  #   usage:
  #     gds2File.printXy( -xyInt => ArrayGds2Ints );
  #     -or-
  #     gds2File.printXy( -xy => ArrayReals );
  #
  #     -xyInt most useful if reading and modifying... -xy if creating from scratch
  #

  def printXy(*arg)
    #### -xyInt most useful if reading and modifying... -xy if creating from scratch
    xyInt = arg['-xyInt']; ## $xyInt should be a reference to an array of internal GDS2 format integers
    xy = arg['-xy']; ## $xy should be a reference to an array of reals
    resolution = @Resolution
    unless xy || xyInt

      raise "printXy expects an xy array reference. Missing -xy => \\\#{array}"
    end
    if xyInt

      xy = xyInt
      resolution = 1
    end
    xyTmp = [] # #don't pollute array passed in
    xy.each do |xyi| ## e.g. 3.4 in -> 3400 out
      xyTmp << snap_int(xyi)
    end
    printGds2Record(type: 'XY', data: xyTmp)
  end
  ############################################################################

  # = Low Level Specific Evaluation Methods
  #

  # == returnFilePosition - return current byte position (NOT zero based)
  #
  #   usage:
  #     $position = gds2File.returnFilePosition;
  #

  def returnFilePosition
    @BytesDone
  end
  ############################################################################

  def tellSize ## old name
    @BytesDone
  end
  ############################################################################

  # == returnBgnextn - returns bgnextn if record is BGNEXTN else returns 0
  #
  #   usage:
  #

  def returnBgnextn
    ## 2 byte signed integer
    isBgnextn ? @RecordData[0] : 0
  end
  ############################################################################

  # == returnDatatype - returns datatype # if record is DATATYPE else returns -1
  #
  #   usage:
  #     $dataTypesFound[gds2File.returnDatatype] = 1;
  #

  def returnDatatype
    ## 2 byte signed integer
    isDatatype ? @RecordData[0] : UNKNOWN
  end
  ############################################################################

  # == returnEndextn- returns endextn if record is ENDEXTN else returns 0
  #
  #   usage:
  #

  def returnEndextn
    ## 2 byte signed integer
    isEndextn ? @RecordData[0] : 0
  end
  ############################################################################

  # == returnLayer - returns layer # if record is LAYER else returns -1
  #
  #   usage:
  #     $layersFound[gds2File.returnLayer] = 1;
  #

  def returnLayer
    ## 2 byte signed integer
    isLayer ? @RecordData[0] : UNKNOWN
  end
  ############################################################################

  # == returnPathtype - returns pathtype # if record is PATHTYPE else returns -1
  #
  #   usage:
  #

  def returnPathtype
    ## 2 byte signed integer
    isPathtype ? @RecordData[0] : UNKNOWN
  end
  ############################################################################

  # == returnPropattr - returns propattr # if record is PROPATTR else returns -1
  #
  #   usage:
  #

  def returnPropattr
    ## 2 byte signed integer
    isPropattr ? @RecordData[0] : UNKNOWN
  end
  ############################################################################

  # == returnPropvalue - returns propvalue string if record is PROPVALUE else returns ''
  #
  #   usage:
  #

  def returnPropvalue
    isPropvalue ? @RecordData[0] : ''
  end
  ############################################################################
  # == returnSname - return string if record type is SNAME else ''
  #
  def returnSname
    isSname ? @RecordData[0] : ''
  end

  ############################################################################
  # == returnString - return string if record type is STRING else ''
  #
  def returnString
    isString ? @RecordData[0] : ''
  end

  ############################################################################
  # == returnStrname - return string if record type is STRNAME else ''
  #
  def returnStrname
    isStrname ? @RecordData[0] : ''
  end

  ############################################################################
  # == returnTexttype - returns texttype # if record is TEXTTYPE else returns -1
  #
  #   usage:
  #     $TextTypesFound[gds2File.returnTexttype] = 1;
  #
  def returnTexttype
    ## 2 byte signed integer
    isTexttype ? @RecordData[0] : UNKNOWN
  end

  ############################################################################
  # == returnWidth - returns width # if record is WIDTH else returns -1
  #
  #   usage:
  #
  def returnWidth
    ## 4 byte signed integer
    isWidth ? @RecordData[0] : UNKNOWN
  end

  ############################################################################
  ############################################################################
  # = Low Level Specific Boolean Methods
  #
  ############################################################################

  # == isAref - true or false depending on whether current record is an aref
  def isAref
    @RecordType == AREF
  end
  ############################################################################

  # == isBgnlib - true or false depending on whether current record is a bgnlib
  #

  def isBgnlib
    @RecordType == BGNLIB
  end
  ############################################################################

  # == isBgnstr - true or false depending on whether current record is a bgnstr
  #

  def isBgnstr
    @RecordType == BGNSTR
  end
  ############################################################################

  # == isBoundary - true or false depending on whether current record is a boundary
  #

  def isBoundary
    @RecordType == BOUNDARY
  end
  ############################################################################

  # == isDatatype - true or false depending on whether current record is datatype
  #

  def isDatatype
    @RecordType == DATATYPE
  end
  ############################################################################

  # == isEndlib - true or false depending on whether current record is endlib
  #

  def isEndlib
    @RecordType == ENDLIB
  end
  ############################################################################

  # == isEndel - true or false depending on whether current record is endel
  #

  def isEndel
    @RecordType == ENDEL
  end
  ############################################################################

  # == isEndstr - true or false depending on whether current record is endstr
  #

  def isEndstr
    @RecordType == ENDSTR
  end
  ############################################################################

  # == isHeader - true or false depending on whether current record is a header
  #

  def isHeader
    @RecordType == HEADER
  end
  ############################################################################

  # == isLibname - true or false depending on whether current record is a libname
  #

  def isLibname
    @RecordType == LIBNAME
  end
  ############################################################################

  # == isPath - true or false depending on whether current record is a path
  #

  def isPath
    @RecordType == PATH
  end
  ############################################################################

  # == isSref - true or false depending on whether current record is an sref
  #

  def isSref
    @RecordType == SREF
  end
  ############################################################################

  # == isSrfname - true or false depending on whether current record is an srfname
  #

  def isSrfname
    @RecordType == SRFNAME
  end
  ############################################################################

  # == isText - true or false depending on whether current record is a text
  #

  def isText
    @RecordType == TEXT
  end
  ############################################################################

  # == isUnits - true or false depending on whether current record is units
  #

  def isUnits
    @RecordType == UNITS
  end
  ############################################################################

  # == isLayer - true or false depending on whether current record is layer
  #

  def isLayer
    @RecordType == LAYER
  end
  ############################################################################

  # == isStrname - true or false depending on whether current record is strname
  #

  def isStrname
    @RecordType == STRNAME
  end
  ############################################################################

  # == isWidth - true or false depending on whether current record is width
  #

  def isWidth
    @RecordType == WIDTH
  end
  ############################################################################

  # == isXy - true or false depending on whether current record is xy
  #

  def isXy
    @RecordType == XY
  end
  ############################################################################

  # == isSname - true or false depending on whether current record is sname
  #

  def isSname
    @RecordType == SNAME
  end
  ############################################################################

  # == isColrow - true or false depending on whether current record is colrow
  #

  def isColrow
    @RecordType == COLROW
  end
  ############################################################################

  # == isTextnode - true or false depending on whether current record is a textnode
  #

  def isTextnode
    @RecordType == TEXTNODE
  end
  ############################################################################

  # == isNode - true or false depending on whether current record is a node
  #

  def isNode
    @RecordType == NODE
  end
  ############################################################################

  # == isTexttype - true or false depending on whether current record is a texttype
  #

  def isTexttype
    @RecordType == TEXTTYPE
  end
  ############################################################################

  # == isPresentation - true or false depending on whether current record is a presentation
  #

  def isPresentation
    @RecordType == PRESENTATION
  end
  ############################################################################

  # == isSpacing - true or false depending on whether current record is a spacing
  #

  def isSpacing
    @RecordType == SPACING
  end
  ############################################################################

  # == isString - true or false depending on whether current record is a string
  #

  def isString
    @RecordType == STRING
  end
  ############################################################################

  # == isStrans - true or false depending on whether current record is a strans
  #

  def isStrans
    @RecordType == STRANS
  end
  ############################################################################

  # == isMag - true or false depending on whether current record is a mag
  #

  def isMag
    @RecordType == MAG
  end
  ############################################################################

  # == isAngle - true or false depending on whether current record is a angle
  #

  def isAngle
    @RecordType == ANGLE
  end
  ############################################################################

  # == isUinteger - true or false depending on whether current record is a uinteger
  #

  def isUinteger
    @RecordType == UINTEGER
  end
  ############################################################################

  # == isUstring - true or false depending on whether current record is a ustring
  #

  def isUstring
    @RecordType == USTRING
  end
  ############################################################################

  # == isReflibs - true or false depending on whether current record is a reflibs
  #

  def isReflibs
    @RecordType == REFLIBS
  end
  ############################################################################

  # == isFonts - true or false depending on whether current record is a fonts
  #

  def isFonts
    @RecordType == FONTS
  end
  ############################################################################

  # == isPathtype - true or false depending on whether current record is a pathtype
  #

  def isPathtype
    @RecordType == PATHTYPE
  end
  ############################################################################

  # == isGenerations - true or false depending on whether current record is a generations
  #

  def isGenerations
    @RecordType == GENERATIONS
  end
  ############################################################################

  # == isAttrtable - true or false depending on whether current record is a attrtable
  #

  def isAttrtable
    @RecordType == ATTRTABLE
  end
  ############################################################################

  # == isStyptable - true or false depending on whether current record is a styptable
  #

  def isStyptable
    @RecordType == STYPTABLE
  end
  ############################################################################

  # == isStrtype - true or false depending on whether current record is a strtype
  #

  def isStrtype
    @RecordType == STRTYPE
  end
  ############################################################################

  # == isEflags - true or false depending on whether current record is a eflags
  #

  def isEflags
    @RecordType == EFLAGS
  end
  ############################################################################

  # == isElkey - true or false depending on whether current record is a elkey
  #

  def isElkey
    @RecordType == ELKEY
  end
  ############################################################################

  # == isLinktype - true or false depending on whether current record is a linktype
  #

  def isLinktype
    @RecordType == LINKTYPE
  end
  ############################################################################

  # == isLinkkeys - true or false depending on whether current record is a linkkeys
  #

  def isLinkkeys
    @RecordType == LINKKEYS
  end
  ############################################################################

  # == isNodetype - true or false depending on whether current record is a nodetype
  #

  def isNodetype
    @RecordType == NODETYPE
  end
  ############################################################################

  # == isPropattr - true or false depending on whether current record is a propattr
  #

  def isPropattr
    @RecordType == PROPATTR
  end
  ############################################################################

  # == isPropvalue - true or false depending on whether current record is a propvalue
  #

  def isPropvalue
    @RecordType == PROPVALUE
  end
  ############################################################################

  # == isBox - true or false depending on whether current record is a box
  #

  def isBox
    @RecordType == BOX
  end
  ############################################################################

  # == isBoxtype - true or false depending on whether current record is a boxtype
  #

  def isBoxtype
    @RecordType == BOXTYPE
  end
  ############################################################################

  # == isPlex - true or false depending on whether current record is a plex
  #

  def isPlex
    @RecordType == PLEX
  end
  ############################################################################

  # == isBgnextn - true or false depending on whether current record is a bgnextn
  #

  def isBgnextn
    @RecordType == BGNEXTN
  end
  ############################################################################

  # == isEndextn - true or false depending on whether current record is a endextn
  #

  def isEndextn
    @RecordType == ENDEXTN
  end
  ############################################################################

  # == isTapenum - true or false depending on whether current record is a tapenum
  #

  def isTapenum
    @RecordType == TAPENUM
  end
  ############################################################################

  # == isTapecode - true or false depending on whether current record is a tapecode
  #

  def isTapecode
    @RecordType == TAPECODE
  end
  ############################################################################

  # == isStrclass - true or false depending on whether current record is a strclass
  #

  def isStrclass
    @RecordType == STRCLASS
  end
  ############################################################################

  # == isReserved - true or false depending on whether current record is a reserved
  #

  def isReserved
    @RecordType == RESERVED
  end
  ############################################################################

  # == isFormat - true or false depending on whether current record is a format
  #

  def isFormat
    @RecordType == FORMAT
  end
  ############################################################################

  # == isMask - true or false depending on whether current record is a mask
  #

  def isMask
    @RecordType == MASK
  end
  ############################################################################

  # == isEndmasks - true or false depending on whether current record is a endmasks
  #

  def isEndmasks
    @RecordType == ENDMASKS
  end
  ############################################################################

  # == isLibdirsize - true or false depending on whether current record is a libdirsize
  #

  def isLibdirsize
    @RecordType == LIBDIRSIZE
  end
  ############################################################################

  # == isLibsecur - true or false depending on whether current record is a libsecur
  #

  def isLibsecur
    @RecordType == LIBSECUR
  end
  ############################################################################

  ############################################################################
  ## support functions

  def getRecordData
    dt = @DataType
    if dt == NO_REC_DATA
      return ''
    elsif dt == INTEGER_2 || dt == INTEGER_4 || dt == REAL_8
      return @CurrentDataList.sub!(/^,/, '').split(/,/)
    elsif dt == ASCII_STRING
      return @CurrentDataList.sub!(/\0/, '')
    else ## bit_array
      return @CurrentDataList
    end
  end
  ############################################################################

  def readRecordTypeAndData
    [recordtypestrings[@RecordType], @RecordData]
  end
  ############################################################################

  def skipGds2RecordData
    readGds2RecordHeader if @INHEADER != true; ## safety - need to read HEADER if INHEADER == UNKNOWN or false
    @INHEADER = false
    @INDATA   = true; # in DATA - actually will be at the end of data by the time we test this...
    ## 4 should have been just read by readGds2RecordHeader
    @FileHandle.seek(@Length - 4, SEEK_CUR); ## seek seems to run a little faster than read
    @DataIndex = UNKNOWN
    true
  end
  ############################################################################

  ### return number of XY coords if XY record
  def returnNumCoords
    if @RecordType == XY ## 4 byte signed integer
      ((@Length - 4) / 8).to_i
    else
      false
    end
  end
  ############################################################################

  def roundNum(num, places)
    format("%.#{places}f", num)
  end
  ############################################################################

  def scaleNum(num, scale)
    raise 'first number passed into scaleNum() must be an integer' if num !~ /^-?\d+/
    num *= scale
    num = int(num + 0.5) if num =~ /\./
    num
  end
  ############################################################################

  def snapNum(num, snap)
    raise 'first value passed into snapNum() must be an integer' if num !~ /^-?\d+$/
    snapLength = length(snap.to_s)
    lean = 1; # #init
    lean = -1 if num < 0
    ## snap to grid..
    littlePart = substr(num, -snapLength, snapLength)
    littlePart = -littlePart if num < 0
    littlePart = int((littlePart / snap) + (0.5 * lean)) * snap
    bigPart = substr(num, 0, -snapLength)
    if bigPart =~ /^[-]?$/
      bigPart = 0
    else
      bigPart *= 10**snapLength
    end
    num = bigPart + littlePart
    num
  end
  ############################################################################

  ############################################################################
  ## some vendor tools have trouble w/ negative angles and angles >= 360
  ## so we normalize to positive equivalent
  ############################################################################
  def posAngle(angle)
    angle += 360.0 while  angle < 0.0
    angle -= 360.0 while  angle >= 360.0
    angle = cleanFloatNum(angle)
    angle
  end
  ############################################################################
  # == recordSize - return current record size
  #
  #   usage:
  #     len = gds2File.recordSize;
  #
  #
  def recordSize
    @Length
  end
  ############################################################################
  # == dataSize - return current record size - 4 (length of data)
  #
  #   usage:
  #     dataLen = gds2File.dataSize;
  #
  def dataSize
    @Length - 4
  end
  ############################################################################

  # == returnUnitsAsArray - return user units and database units as a 2 element array
  #
  #   usage:
  #     ($uu,$dbu) = gds2File.returnUnitsAsArray;
  #
  #

  def returnUnitsAsArray
    return [@UUnits, @DBUnits] if isUnits
    []
  end
  ############################################################################

  #######
  def subbyte
    (what, where, howmuch) = @_
    what.unpack("x#{where} C#{howmuch}")
  end
  ############################################################################

  # return GDS2 module version string
  def version ## GDS2::version();
    VERSION
  end
  ############################################################################
  # return GDS2 module revision string
  def revision ## GDS2::revision();
    REVISION
  end
  ############################################################################

  def getElmSpace
    GDS2.elmspace
  end
  ############################################################################

  def putElmSpace(arg)
    GDS2.elmspace = arg
  end
  ############################################################################

  def getStrSpace
    GDS2.strspace
  end
  ############################################################################

  def putStrSpace(arg)
    GDS2.strspace = arg
  end
  ############################################################################
end

# = GDS2 Stream Format
#
#  #####################################################################################
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
#  #####################################################################################
#
#
# = Backus-naur representation of GDS2 Stream Syntax
#
#  ############################################################################
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
#  ############################################################################
#
#
# = GDS2 Stream Record Datatypes
#
#  ############################################################################
#  NO_REC_DATA   =  0;
#  BIT_ARRAY     =  1;
#  INTEGER_2     =  2;
#  INTEGER_4     =  3;
#  REAL_4        =  4; ## NOT supported, never really used
#  REAL_8        =  5;
#  ASCII_STRING  =  6;
#  ############################################################################
#
#
# = GDS2 Stream Record Types
#
#  ############################################################################
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
