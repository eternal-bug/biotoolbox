# ADVANCED INSTALLATION

This is a brief, advanced installation guide for getting a complete installation. I 
recommend using a simple CPAN package manager such as [CPAN Minus](https://metacpan.org/pod/App::cpanminus) 
or `cpanm`. Note that in the following example commands, `cpanm` is given a Perl module name, 
which is used to query [CPAN](https://metacpan.org), but it can also easily take a URL or 
a downloaded archive file. 

Note that `Make` and compilation tools, e.g. `GCC` or `clang`, are required. Most linux 
distributions have these available as an optional install if they're not already 
available. On MacOS, install the Xcode Command Line Tools. 

For additional guidance when working on MacOS, see [MacOS Notes](MacOSNotes.md).

## Perl installations and locations

As a Perl package, BioToolBox needs to be installed under a Perl installation. It is 
not dependent on a specific Perl release version, although later releases (5.16 
or newer) are preferred. Nearly every unix-like OS (Linux, MacOS) includes a system Perl 
installation. If not, one can be installed, either from the OS package manager or 
from source.

Follow one of these options. 

### Home library

When you want to use the system-installed Perl (often `/usr/bin/perl`), but do not have 
write permissions to the system, you can install packages in your home directory. To do 
this, you should first install [local::lib](https://metacpan.org/pod/local::lib), which 
sets up a `perl5` directory for local (home) module installations. The path is set 
appropriately by adding a statement to your home `.profile` or other equivalent file as 
described in the documentation. This can also be used for targeted, standalone 
installations; adjust accordingly. For example, the following command will install 
`local::lib` and the CPAN Minus

    $ curl -L https://cpanmin.us | perl - -l $HOME/perl5 local::lib App::cpanminus \
    && echo 'eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)"' >> ~/.profile \
    && . ~/.profile

### Custom installation

When the system Perl is old (because many vendor OS Perl installations are sadly out of 
date), or you want or need to install a newer, modern Perl, but cannot or do not want to 
overwrite the system Perl, then you can and should install a new Perl version. This can 
be installed anywhere you have read/write access, including your home directory or 
wherever. While a new Perl version can be manually downloaded and installed from the 
main [Perl](https://www.perl.org) site, there are easier ways.

An alternate package manager may be used to install a Perl version in a generally
available location. For example, MacOS users can easily install a modern Perl using
[Homebrew](https://brew.sh). Similarly, Linux (and evidently Microsoft Windows Subsystem
for Linux) users can use [Linuxbrew](http://linuxbrew.sh). These typically install the
latest production release, currently `5.28`, with a single command.

To install a Perl in your home directory (or other location) with a simple, but powerful,
tool, use the excellent [PerlBrew](https://perlbrew.pl). This tool can painlessly compile,
install, and manage one or more Perl release versions side-by-side, allowing you to easily
switch between releases with a simple command. It also manages multiple `local::lib`
installations, in case you want to isolate packages. 

BioToolBox does not utilize threading (it uses forks for parallel execution), so if you 
have a choice, compile a non-threaded Perl for a (very) slight performance gain. For 
those adventurous to try, BioToolBox does work under [cperl](http://perl11.org/cperl/), 
although installing some prerequisite modules is a trying experience (many failed 
tests and partial functionality).

### System installation

For privileged installations (requiring `root` access or `sudo` privilege) you probably
already know what to do. You can use the `--sudo` or `-S` option to `cpanm`. Note that
installing lots of packages in the OS vendor system perl is generally not recommended, as
it could interfere with other vital OS functions or programs that expect certain versions
or modules to be present. It's best to use one of the other two methods.

## External libraries

There are two external C libraries that are required for reading Bam and BigWig files. 
Note that both Perl modules [Bio::DB::HTS](https://metacpan.org/pod/Bio::DB::HTS) and 
[Bio::DB::Big](https://metacpan.org/pod/Bio::DB::Big) include `INSTALL.pl` scripts within 
their bundles that can compile these external libraries for you in a semi-automated 
control. Proceed here if you wish to have more control over what and where these are 
installed.

- [HTSlib](https://github.com/samtools/htslib)

   Follow the directions within for installation. [Version
   1.8](https://github.com/samtools/htslib/releases/download/1.8/htslib-1.8.tar.bz2) is
   known to work well, although newer versions should work too. By default, it installs
   into `/usr/local`, or it may be set to another directory (`$HOME` for example) by
   adding `--prefix=$HOME` option to the `configure` step. This may also be available via
   OS or other package managers.

- [libBigWig](https://github.com/dpryan79/libBigWig)

    Follow the directions within for installation. By default, it installs into 
    `/usr/local`. To change to a different location, manually edit the `Makefile`
    to change `prefix` to your desired location, and run `make && make install`.

## Perl modules

The following Perl packages should be explicitly installed. Most of these will 
bring along a number of dependencies (which in turn bring along more dependencies). In 
the end you will have installed dozens of packages. 


- [Module::Build](https://metacpan.org/pod/Module::Build)

    This may or may not need to be installed, depending on the age of your Perl 
    installation and how much else has been installed. It was part of the standard 
    Perl distribution up until version 5.21. 

- [BioPerl](https://metacpan.org/pod/BioPerl)

    The BioPerl package is a large bundle that brings along a number of extraneous 
    modules and bundled scripts, the vast majority of which is not needed by Bio::ToolBox.
    This is required by Bio::DB::HTS and all of the legacy adapters. 
    
    If you build this manually, or run `cpanm` with the `--interactive` option, you 
    can interactively choose what scripts to include or not include. By default, it 
    installs all additional scripts. None of the included scripts are required by 
    BioToolBox.

- [Bio::DB::HTS](https://metacpan.org/pod/Bio::DB::HTS)

    This provides a perl interface to the [HTSlib](https://github.com/samtools/htslib) 
    library for working with Bam files. It should be able to identify HTSLIB in standard 
    library locations, such as `/usr/local` for example, on its own. For non-standard 
    locations, specify the location of the HTSlib path to `Build.PL` using the 
    `--htslib` option. 

- [Bio::DB::Big](https://metacpan.org/pod/Bio::DB::Big)

    This provides a perl interface to the UCSC-style bigWig and bigBed formats. 
    As with HTSlib, this should be able to identify the libBigWig library in standard 
    locations, but with non-standard locations, you may specify the path with the 
    `--libbigwig` option to `Build.PL`. 
    
    *NOTE*: The distribution from CPAN will install dozens of unnecessary modules for
    remote URL testing. You may be better off installing from
    [source](https://github.com/Ensembl/Bio-DB-Big/archive/master.zip).

- [Parallel::ForkManager](https://metacpan.org/pod/Parallel::ForkManager)

    This is highly recommended to get multi-cpu support for some of the data collection 
    scripts, which can otherwise get slow with a single thread.

- [Set::IntervalTree](https://metacpan.org/pod/Set::IntervalTree)

    This is necessary for optional functionality (quick intersection of genomic 
    intervals, such as black lists) for a few scripts, namely `bam2wig.pl`.

- [Bio::DB::SeqFeature::Store](https://metacpan.org/pod/Bio::DB::SeqFeature::Store)

	This used to be part of the BioPerl distribution prior to release 1.7, but is now
	split into its own distribution. If you wish to use annotation databases, install
	this, along with a SQL driver, such as
	[DBD::SQLite](https://metacpan.org/pod/DBD::SQLite) (recommended) or
	[DBD::mysql](https://metacpan.org/pod/DBD::mysql) (fancy multi-user installations).


An example of installing these Perl modules with `cpanm` is below. This assumes that 
you have `local::lib` or a writable Perl installation in your `$PATH`. Adjust accordingly.

    $ cpanm Module::Build BioPerl
    $ cpanm --configure-args="--htslib $HOME" Bio::DB::HTS
    $ cpanm --configure-args="--libbigwig $HOME" Bio::DB::Big
    $ cpanm Parallel::ForkManager Set::IntervalTree
    $ cpanm Bio::DB::SeqFeature::Store DBD::SQLite
    $ cpanm Bio::ToolBox

## External applications

Some programs, notably [bam2wig.pl](https://metacpan.org/pod/distribution/Bio-ToolBox/scripts/bam2wig.pl) 
among others, requires external UCSC utilities for converting wig files to bigWig. You may 
download these from the UCSC Genome Browser utilities section for either 
[linux](http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/) or 
[MacOS](http://hgdownload.soe.ucsc.edu/admin/exe/macOSX.x86_64/). Copy them to your 
`bin` directory in your `PATH`, for example `$HOME/bin`, `$HOME/perl5/bin`, or 
`/usr/local/bin`. Be sure to make them executable by running `chmod +x` on each file.

- wigToBigWig
- bedGraphToBigWig
- bigWigToWig
- bedToBigBed

An example for downloading on linux:

    $ for name in wigToBigWig bedGraphToBigWig bigWigToWig bedToBigBed; \
    do curl http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/$name > $HOME/bin/$name \
    && chmod +x $HOME/bin/$name; done;


## Legacy Perl modules

These are additional legacy Perl modules that are supported (for example, if you still 
have a [GBrowse](http://gmod.org/wiki/GBrowse) installation), but are either not required 
or have been superseded by other modules. 

- [Bio::DB::Sam](https://metacpan.org/pod/Bio::DB::Sam)
- [Bio::DB::BigWig](https://metacpan.org/pod/Bio::DB::BigWig)
- [Bio::DB::BigBed](https://metacpan.org/pod/Bio::DB::BigBed)
- [Bio::DB::USeq](https://metacpan.org/pod/Bio::DB::USeq)
- [Bio::Graphics::Wiggle](https://metacpan.org/pod/Bio::Graphics::Wiggle)

Some notes are below for anyone who may need to install these. 

### Sam library

The Bio::DB::Sam library _only_ works with the legacy Samtools version, which included
both the C libraries, headers, and executables; use version
[0.1.19](https://github.com/samtools/samtools/archive/0.1.19.tar.gz) for best results. You
will need to compile the Samtools code, but you do not have to install it (the library is
not linked). Before compiling, edit the Makefile to include the cflags `-fPIC` and (most
likely) `-m64` for 64 bit OS. Export the `SAMTOOLS` environment variable to the path of
the Samtools build directory, and then you can proceed to build the Perl module; it should
find the necessary files using the `SAMTOOLS` environment variable. You may obtain the
latest source from
[here](https://github.com/GMOD/GBrowse-Adaptors/tree/master/Bio-SamTools).

### UCSC BigFile library

The Bio::DB::BigWig and Bio::DB::BigBed modules are part of the same distribution, 
[Bio-BigFile](https://github.com/GMOD/GBrowse-Adaptors/tree/master/Bio-BigFile). Only 
use the code from the GitHub repository, as it should be compatible with recent UCSC 
libraries, whereas the distribution on CPAN is out of date. 

You will need the UCSC source code; the
[userApps](http://hgdownload.soe.ucsc.edu/admin/exe/) source code is sufficient, rather
than the entire browser code. Version 375, at the time of this writing, works. This
requires at least `OpenSSL` and `libpng` libraries to compile the required library; on
MacOS, these need to be installed independently (see [Homebrew](https://brew.sh) for
example). There are other requirements, such as MySQL client libraries, that are needed if
you want to compile the actual command line utilities, if so desired. 

For purposes here, only the library needs to be compiled. It does not need to be 
installed, as nothing is linked. Therefore, you can safely ignore the main `Makefile` 
commands. Below are the steps for compiling just the requisite C library for installing 
the Perl module.

Edit the file `kent/src/inc/common.mk`, and insert `-fPIC` into the `CFLAGS` variable. If 
you have installed any libraries in non-standard locations, e.g. `openssl` installed via 
HomeBrew on MacOS, then add these paths to the `HG_INC` variable. Save the file. 

To simplify compilation, you can skip the main Makefile and simply compile only the 
libraries that you need. First, export the `MACHTYPE` environment variable to an 
acceptable simple value, usually `x86_64`.

Next, move to the included `kent/src/htslib`, and compile this library by issuing the 
`make` command.

Move to the `kent/src/lib` directory, and compile the library by issuing the `make` 
command. If it compiles successfully, you should get a `jkweb.a` file in the `lib/x86_64` 
directory.

Finally, you can return to the Perl module. First, set the `KENT_SRC` environment 
variable to the full path of the `kent/src` build directory (otherwise you will need to 
interactively provide the Perl module Build script this path). Then issue the standard 
`Build.PL` commands to build, test, and install the Perl modules.





