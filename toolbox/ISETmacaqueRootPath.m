function rootDirName = ISETmacaqueRootPath()
    [rootDirName,q] = fileparts(which(mfilename));
    rootDirName = strrep(rootDirName, '/toolbox','');
end