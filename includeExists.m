function exists = includeExists( lib )

    fid = fopen( '.__test__.h', 'w' );
    fprintf( fid, '#include <%s>\n', lib );
    fclose(fid);
    
    fid = fopen( '.__testinclude.sh', 'w' );
    fprintf( fid, 'if gcc -E .__test__.h\n' );
    fprintf( fid, ' then\n' );
    fprintf( fid, 'echo 1\n' );
    fprintf( fid, ' else\n' );
    fprintf( fid, 'echo 0\n' );
    fprintf( fid, 'fi\n' );
    
    [~,C] = system('sh .__testinclude.sh');
    
    exists = str2num( C(end-1) ); %#ok
end