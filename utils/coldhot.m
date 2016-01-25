function ch = coldhot(m)
%COLDHOT   Blue-to-white-to-red color map.
%   COLDHOT(M) returns an M-by-3 matrix containing the colormap.
%   COLDHOT, by itself, is the same length as the current colormap.
%
%   For example, to reset the colormap of the current figure:
%
%             colormap(coldhot)
%
%   See also HSV, HOT, COOL, BONE, COPPER, PINK, FLAG, 
%   COLORMAP, RGBPLOT.

%   Giuseppe 7 Apr 03

if nargin < 1, m = size(get(gcf,'colormap'),1); end

mid = round(m/2);
off = rem (m, 2);
up = (0:1/(mid-1):1)';
dw = up(end-off:-1:1);
ch = [up up ones(mid,1); ones(mid-off,1) dw dw];