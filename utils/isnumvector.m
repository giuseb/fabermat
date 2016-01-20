function retval = isnumvector (s)

%ISNUMVECTOR(S) returns true when S is a numeric vector with only one
%               non-singleton dimension.
%
%Last modified: 19 Jan 2016

retval = isnumeric(s) & numel(s)==length(s);