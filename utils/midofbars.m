function [xc, yc] = midofbars (b)

%MIDOFBARS  position of bars in bar charts
%
%   X = MIDOFBARS(B) returns the midpoint of each bar in B, a handle to
%   barseries graphics objects returned by BAR.
%
%   [X Y] = MIDOFBARS(B) also returns the ydata, i.e. the height of each bar
%
%   The function is useful to add, for example, error bars to a bar chart;
%   see for example barerr.m
%   
%Last modified: 1 Mar 13

xc = [];
yc = [];
for bo = b
    x = get (get (bo, 'children'), 'xdata');
    xm = x(1,:) + diff (x(2:3, 1)) / 2;
    xc = [xc; xm];
    y = get (bo, 'ydata');
    yc = [yc; y];
end
xc = xc';
yc = yc';