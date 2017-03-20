function compileGlueM()

    % mexopt = {'-largeArrayDims'}; 
    mexopt = {};
    zmqpath = fullfile('3rdparty', 'zeromq-4.2.1');
    outdir = 'compiled';
    
    includepath = fullfile( zmqpath, 'include' );
    sourcepath = fullfile( zmqpath, 'src' );
    
    fileString = genString( sourcepath );
    includeString = genString( includepath );
    
    file = fopen( fullfile( sourcepath, 'platform.hpp' ), 'w' );
    
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
        '#ifndef __PLATFORM_HPP_INCLUDED__', ...
        '#define __PLATFORM_HPP_INCLUDED__', ...
        '#define ZMQ_HAVE_LINUX', ...
        '#endif' );
    end
    
    fclose(file);
    
    fileStrings = genStrings( sourcepath, '*.cpp' );
    
    out = 'glue';
    for j = 1 : numel( fileStrings )
        mex( '-c', mexopt{:}, '-outdir', outdir, ['-I"', fullfile(pwd, sourcepath), '"'], ['-I"', fullfile(pwd, includepath), '"'], fileStrings{j} );
    end

    %'-DHAS_PTHREAD=1', ...
    %    sprintf('-DNMAXTHREADS=%i', ar.config.nMaxThreads), ...    

    %mex( mexopt{:}, '-output', out, includes, '-DHAS_PTHREAD=1', ...
    %    sprintf('-DNMAXTHREADS=%i', ar.config.nMaxThreads), ...
    %    which('udata.c'), which('arSimuCalc.c'), objectsstr{:});
    
end

% Generate as single string
function str = genString( path )
    fns = ls( path );
    fns = setdiff( fns, {'.', '..'} );
    
    str = fullfile(path, fns{1});
    for a = 2 : numel( fns )
        str = sprintf( '%s %s', str, fullfile( path, fns{a} ) );
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