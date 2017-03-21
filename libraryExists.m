function hasLib = libraryExists(lib)
    [~, D] = system( sprintf('ldconfig -p | grep %s', lib) );
    if ( numel(D) > 1 )
        hasLib = 1;
    else
        hasLib = 0;
    end
end

