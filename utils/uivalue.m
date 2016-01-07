function retval = uivalue (handle)

%UIVALUE(HANDLE)  returns the numeric value of the object HANDLE
%
%Last modified: 30 Dec 15

retval = str2double(get (handle, 'string'));