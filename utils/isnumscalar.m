function rv = isnumscalar (s)

%ISNUMSCALAR(S) returns true when S is a numeric scalar, false otherwise
%
%Last modified: 19 Jan 16 --Giuseppe Bertini

rv = isnumeric(s) & numel(s)==1;