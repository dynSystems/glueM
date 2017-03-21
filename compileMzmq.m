function compileMzmq()
    % mexopt = {'-largeArrayDims'}; 
    mexopt = {};
    
    compileUtility = 0;
    if ( ispc )
        % Include Winsock libraries
        mexopt{end+1} = '-lWs2_32.lib';
        mexopt{end+1} = '-lIphlpapi.lib';
    end
    
    % Paths to the libraries
    zmqpath = fullfile('3rdparty', 'zeromq-4.2.1');
    mzmqpath = fullfile('3rdparty', 'matlab_zmq');
    
    % Header files
    zmqheaderpath = fullfile( zmqpath, 'include' );
    mzmqsrcpath = fullfile( mzmqpath, 'src' );
    mzmqutilpath = fullfile( mzmqsrcpath, 'util' );
    
    % Source files
    utildir = 'mzmq_util';
    outdir = fullfile('3rdparty', 'matlab_zmq', 'lib', '+zmq', '+core');

    % Compile utility files
    if ( compileUtility )
        fprintf( 'Compiling mzmq utility functions ...\n' );
        utilSources = genStrings( mzmqutilpath, '*.c' );
        for j = 1 : numel( utilSources )
            mex( '-c', mexopt{:}, '-DZMQ_STATIC', '-outdir', utildir, ['-I"' zmqheaderpath '"'], [ '"' utilSources{j} '"' ] );
        end
    end
    
    % Compile the call functions
    funcsourcepath = fullfile( mzmqsrcpath, 'core' );
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