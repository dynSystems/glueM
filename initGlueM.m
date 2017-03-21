function initGlueM()

    zmqpath = fullfile('3rdparty', 'zeromq-4.2.1');
    mzmqpath = fullfile('3rdparty', 'matlab_zmq');
    compiled = 0;
    
    if ~exist( zmqpath, 'dir' )
        error( 'ZeroMQ library missing!' );
    end
    if ~exist( mzmqpath, 'dir' )
        error( 'ZeroMQ MATLAB bindings missing!' );
    end
    
    if ( ispc )
        mw64 = dir(fullfile(mzmqpath, 'lib', '+zmq', '+core', '*.mexw64'));
        mw32 = dir(fullfile(mzmqpath, 'lib', '+zmq', '+core', '*.mexw32'));
        mexfiles = union( {mw64.name}, {mw32.name} );
        if ~isempty( mexfiles )
            compiled = 1;
        end
    else
        ma64 = dir(fullfile(mzmqpath, 'lib', '+zmq', '+core', '*.mexa64'));
        ma32 = dir(fullfile(mzmqpath, 'lib', '+zmq', '+core', '*.mexa32'));
        mexfiles = union( {ma64.name}, {ma32.name} );
        if ~isempty( mexfiles )
            compiled = 1;
        end
    end
    
    if ( ~compiled )
        fprintf( 'ZMQ library and bindings have not yet been compiled! Compiling ...\n' );
        compileGlueM;
    end
    
    % Add the library class to the path so that it can be found
    addpath(fullfile(pwd, mzmqpath, 'lib'));
end

