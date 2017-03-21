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
    
    % Target directory
    outdir = fullfile( mzmqpath, 'lib', '+zmq', '+core' );
    
    % Write config file for compiling ZMQ
    fprintf( 'Generating zmq library files ...\n' );
    file = fopen( fullfile( zmqsrcpath, 'platform.hpp' ), 'w' );
    % ZMQ_HAVE_LINUX
    if ( ispc )
        fprintf( file, '%s\n', ...
            '#ifndef __PLATFORM_HPP_INCLUDED__', ...
            '#define __PLATFORM_HPP_INCLUDED__', ...
            '#define ZMQ_HAVE_WINDOWS', ...
            '#define ZMQ_USE_SELECT', ...
            '#define DLL_EXPORT', ...
            '#define _CRT_SECURE_NO_WARNINGS', ...
            '#define _WINSOCK_DEPRECATED_NO_WARNINGS', ...
            '#define WIN32_LEAN_AND_MEAN', ...
            '#endif' );
    else
        fprintf( file, '%s\n', ...
            '#ifndef __PLATFORM_HPP_INCLUDED__', ...
            '#define __PLATFORM_HPP_INCLUDED__', ...
            '#define ZMQ_HAVE_LINUX', ...
            '#define ZMQ_STATIC', ...
            '#endif' );
    end
    fclose(file);
    
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
    compiledUtil = genStrings( fullfile('mzmq_util'), '*.*' );
    compiledZmq = genStrings( fullfile('compiled'), '*.*' );
    for j = 1 : numel( funcSources )
        mex( mexopt{:}, '-DZMQ_STATIC', '-outdir', outdir, ['-I"' zmqheaderpath '"'], ['-I"' mzmqsrcpath '"'], compiledZmq{:}, compiledUtil{:}, ['"' funcSources{j} '"'] );
    end
    
    % Clean up intermediate directories
    rmdir( 'mzmq_util', 's' );
    rmdir( 'compiled', 's' );    
end

% Generate as list with paths
function str = genStrings( path, filt )
    fns = ls( fullfile( path, filt ) );
    fns = setdiff( fns, {'.', '..'} );
    
    for a = 1 : numel( fns )
        str{a} = fullfile(path, fns{a});
    end
end