function compileGlueM()

    zmqpath = fullfile('3rdparty', 'zeromq-4.2.1');
    mzmqpath = fullfile('3rdparty', 'matlab_zmq');
    
    mexopt = {};
    
    if ( ispc )
        % Include Winsock libraries
        mexopt{end+1} = '-lWs2_32.lib';
        mexopt{end+1} = '-lIphlpapi.lib';
    end
    
    % Determine source paths
    zmqheaderpath   = fullfile( zmqpath, 'include' );
    zmqsrcpath      = fullfile( zmqpath, 'src' );
    mzmqsrcpath     = fullfile( mzmqpath, 'src' );
    mzmqutilpath    = fullfile( mzmqsrcpath, 'util' );
    funcsourcepath  = fullfile( mzmqsrcpath, 'core' );
    
    % Temporary directories
    tempzmqdir = '__zmq';
    temputildir = '__mzmq_util';
    mkdir( tempzmqdir );
    mkdir( temputildir );
    
    % Target directory
    outdir = fullfile( mzmqpath, 'lib', '+zmq', '+core' );
    
    % Write config file for compiling ZMQ
    fprintf( 'Generating zmq library files ...\n' );
    file = fopen( fullfile( zmqsrcpath, 'platform.hpp' ), 'w' );
    
    if ( ispc )
        content = { '#ifndef __PLATFORM_HPP_INCLUDED__', ...
                    '#define __PLATFORM_HPP_INCLUDED__', ...
                    '#define ZMQ_HAVE_WINDOWS', ...
                    '#define ZMQ_USE_SELECT', ...
                    '#define DLL_EXPORT', ...
                    '#define _CRT_SECURE_NO_WARNINGS', ...
                    '#define _WINSOCK_DEPRECATED_NO_WARNINGS', ...
                    '#define WIN32_LEAN_AND_MEAN', ...
                    '#endif' };
                
        fprintf( file, '%s\n', content{:} );
    else
        islinux = 1;
        if ( islinux )
            os = '#define ZMQ_HAVE_LINUX';
        else
            os = '#define ZMQ_HAVE_OSX';
        end
        
        % Determine which messaging system to use
        if ( includeExists('sys/event.h') )
            poller = 'ZMQ_USE_KQUEUE';
        %elseif ( includeExists('sys/epoll.h') )
        %    poller = 'ZMQ_USE_EPOLL_CLOEXEC';
        elseif ( includeExists('sys/devpoll.h') )
            poller = 'ZMQ_USE_DEVPOLL';
        elseif ( includeExists('sys/pollset.h') )
            poller = 'ZMQ_USE_POLLSET';
        elseif ( includeExists('sys/poll.h') )    
            poller = 'ZMQ_USE_POLL';
        else
            error( 'Could not find suitable polling library' );
        end
        fprintf( 'Using poller: %s\n', poller );
        
        % Grab list of include files and libraries installed on the system
        defs          = linuxDefs();
        [defs2, libs] = linuxLibs();
        content = {     '#ifndef __PLATFORM_HPP_INCLUDED__', ...
                        '#define __PLATFORM_HPP_INCLUDED__', ...
                        os, ...
                        sprintf( '#define %s', poller ), ...
                        defs{:}, ...
                        defs2{:}, ...
                        '#endif' }; %#ok
        
        fprintf( file, '%s\n', content{:} );
        
        % Get rid of the irritating -ansi in the default mex options
        % in order to make sure that // doesn't raise errors
        L = fileread(fullfile(matlabroot, 'bin', 'mexopts.sh'));
        L = strrep(L, '-ansi', '');
        optsfid = fopen('custommexopts.sh', 'w');
        fprintf( optsfid, '%s', L );
        fclose( optsfid );
        mexopt{end+1} = '-f';
        mexopt{end+1} = fullfile( pwd, 'custommexopts.sh' );
        
        % Link required libraries
        mexopt = {mexopt{:} libs{:}}; %#ok
    end
    fclose(file);
    
    % TO DO: Defines that are currently not used
    % ZMQ_USE_LIBSODIUM or ZMQ_USE_TWEETNACL (different security packages)
    % ZMQ_HAVE_CURVE (encryption package available)
    
    % Compile zmq library to object files
    fprintf( 'Compiling zmq to object files ...\n' );
    zmqsrc = genStrings( zmqsrcpath, '*.cpp' );
    for j = 1 : numel( zmqsrc )
        mex( '-c', mexopt{:}, '-DZMQ_STATIC', '-outdir', tempzmqdir, ['-I"', fullfile('.', zmqsrcpath), '"'], ['-I"', fullfile('.', zmqheaderpath), '"'], ['"' zmqsrc{j} '"'] );
    end
    
    % Compile utility files
	fprintf( 'Compiling mzmq utility functions ...\n' );
    utilSources = genStrings( mzmqutilpath, '*.c' );
    for j = 1 : numel( utilSources )
        mex( '-c', mexopt{:}, '-DZMQ_STATIC', '-outdir', temputildir, ['-I"' zmqheaderpath '"'], [ '"' utilSources{j} '"' ] );
    end
    
    % Compile the call functions
    funcSources = genStrings( funcsourcepath, '*.c' );
    fprintf( 'Compiling mzmq functions ...\n' );
    compiledUtil = genStrings( fullfile(temputildir), '*.*' );
    compiledZmq = genStrings( fullfile(tempzmqdir), '*.*' );
    for j = 1 : numel( funcSources )
        [folder, name, ~] = fileparts( funcSources{j} );
        mex( mexopt{:}, '-DZMQ_STATIC', ['-I"' zmqheaderpath '"'], ['-I"' mzmqsrcpath '"'], compiledZmq{:}, compiledUtil{:}, ['"' funcSources{j} '"'], '-output', fullfile(outdir, name) );
    end
    
    % Clean up intermediate directories
    rmdir( tempzmqdir, 's' );
    rmdir( temputildir, 's' );
end

% Generate as list with paths
function str = genStrings( path, filt )
    fns = dir( fullfile( path, filt ) );
    fns = {fns.name};
    fns = setdiff( fns, {'.', '..'} );
    
    for a = 1 : numel( fns )
        str{a} = fullfile(path, fns{a}); %#ok<AGROW>
    end
end

function defs = linuxDefs()
    filesToCheck = { ...
        { 'alloca.h',                   '#define HAVE_ALLOCA_H' }, ...
        { 'arpa/inet.h',                '#define HAVE_ARPA_INET_H' }, ...
        { 'dlfcn.h',                    '#define HAVE_DLFCN_H' }, ...
        { 'errno.h',                    '#define HAVE_ERRNO_H' }, ...
        { 'gssapi/gssapi_generic.h',    '#define HAVE_GSSAPI_GSSAPI_GENERIC_H' }, ...
        { 'ifaddrs.h',                  '#define HAVE_IFADDRS_H' }, ...
        { 'inttypes.h',                 '#define HAVE_INTTYPES_H' }, ...
        { 'limits.h',                   '#define HAVE_LIMITS_H' }, ...
        { 'memory.h',                   '#define HAVE_MEMORY_H' }, ...
        { 'netinet/in.h',               '#define HAVE_NETINET_IN_H' }, ...
        { 'netinet/tcp.h',              '#define HAVE_NETINET_TCP_H' }, ...
        { 'stddef.h',                   '#define HAVE_STDDEF_H'  }, ...
        { 'stdint.h',                   '#define HAVE_STDINT_H' }, ...
        { 'stdlib.h',                   '#define HAVE_STDLIB_H' }, ...
        { 'strings.h',                  '#define HAVE_STRINGS_H' }, ...
        { 'string.h',                   '#define HAVE_STRING_H' }, ...
        { 'sys/eventfd.h',              '#define HAVE_SYS_EVENTFD_H' }, ...
        { 'sys/socket.h',               '#define HAVE_SYS_SOCKET_H' }, ...
        { 'sys/stat.h',                 '#define HAVE_SYS_STAT_H' }, ...
        { 'sys/time.h',                 '#define HAVE_SYS_TIME_H' }, ...
        { 'sys/types.h',                '#define HAVE_SYS_TYPES_H' }, ...
        { 'sys/uio.h',                  '#define HAVE_SYS_UIO_H' }, ...
        { 'time.h',                     '#define HAVE_TIME_H' }, ...
        { 'unistd.h',                   '#define HAVE_UNISTD_H' }, ...
        { 'sys/uio.h',                  '#define ZMQ_HAVE_UIO' }, ...
    };

    defs = {};
    for jD = 1 : length( filesToCheck )
        if ( includeExists( filesToCheck{jD}{1} ) )
            defs{end+1} = filesToCheck{jD}{2}; %#ok
        end
    end
end

function [defs, libs] = linuxLibs()
    libsToCheck = { ...
        { 'libdl',      '#define HAVE_LIBDL',       '-ldl' }, ...
        { 'iphlpapi',   '#define HAVE_LIBIPHLPAPI', '-liphlpapi' }, ...
        { 'libnsl',     '#define HAVE_LIBNSL',      '-lnsl' }, ...
        { 'libpthread', '#define HAVE_LIBPTHREAD',  '-lpthread' }, ...
        { 'rpcrt4',     '#define HAVE_LIBRPCRT4',   '-lrpcrt4' }, ...
        { 'librt',      '#define HAVE_LIBRT',       '-lrt' }, ...
        { 'socket',     '#define HAVE_LIBSOCKET',   '-lsocket' }, ...
        { 'ws2_32',     '#define HAVE_LIBWS2_32',   '-lws2_32' }, ...
    };

    defs = {};
    libs = {};
    for jD = 1 : length( libsToCheck )
        if ( libraryExists( libsToCheck{jD}{1} ) )
            defs{end+1} = libsToCheck{jD}{2}; %#ok
            libs{end+1} = libsToCheck{jD}{3}; %#ok
        end
    end     
end

%/* Define to 1 if you have the `clock_gettime' function. */
%#undef HAVE_CLOCK_GETTIME
%/* Define to 1 if you have the declaration of `LOCAL_PEERCRED', and to 0 if you don't. */
%#undef HAVE_DECL_LOCAL_PEERCRED
%/* Define to 1 if you have the declaration of `SO_PEERCRED', and to 0 if you
%   don't. */
%#undef HAVE_DECL_SO_PEERCRED
%/* Define to 1 if you have the `fork' function. */
%#undef HAVE_FORK
%/* Define to 1 if you have the `freeifaddrs' function. */
%#undef HAVE_FREEIFADDRS
%/* Define to 1 if you have the `gethrtime' function. */
%#undef HAVE_GETHRTIME
%/* Define to 1 if you have the `getifaddrs' function. */
%#undef HAVE_GETIFADDRS
%/* Define to 1 if you have the `gettimeofday' function. */
%#undef HAVE_GETTIMEOFDAY
%/* The libunwind library is to be used */
%#undef HAVE_LIBUNWIND
%/* Define to 1 if you have the `memset' function. */
%#undef HAVE_MEMSET
%/* Define to 1 if you have the `mkdtemp' function. */
%#undef HAVE_MKDTEMP
%/* Define to 1 if you have the `perror' function. */
%#undef HAVE_PERROR
%/* Define to 1 if you have the `posix_memalign' function. */
%#undef HAVE_POSIX_MEMALIGN
%/* Define to 1 if you have the `socket' function. */
%#undef HAVE_SOCKET
%/* Define to 1 if stdbool.h conforms to C99. */
%#undef HAVE_STDBOOL_H

