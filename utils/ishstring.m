function retval = ishstring (s)

%ISHSTRING   True for horizontal character strings
%   ISHSTRING(S) returns true if ISCHAR(S) and S has only one
%   non-singleton dimension
%
%Last modified: 26 Apr 16

if ischar(s) && numel(s)==size(s,2)
   retval = true;
else
   retval = false;
end