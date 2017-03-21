function compileGlueM()

    % mexopt = {'-largeArrayDims'}; 
    mexopt = {};
    zmqpath = fullfile('3rdparty', 'zeromq-4.2.1');
    outdir = 'compiled';
    
    zmqheaderpath = fullfile( zmqpath, 'include' );
    zmqsrcpath = fullfile( zmqpath, 'src' );
    
    % Write config
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
        mex( '-c', mexopt{:}, '-DZMQ_STATIC', '-outdir', outdir, ['-I"', fullfile('.', zmqsrcpath), '"'], ['-I"', fullfile('.', zmqheaderpath), '"'], ['"' zmqsrc{j} '"'] );
    end
end

% Generate as list with paths
function str = genStrings( path, filt )
    fns = ls( fullfile( path, filt ) );
    fns = setdiff( fns, {'.', '..'} );
    
    for a = 1 : numel( fns )
        str{a} = fullfile(path, fns{a});
    end
end