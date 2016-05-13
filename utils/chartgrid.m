function [fig, sub] = chartgrid (down, across, dist)

% chartgrid.m    places empty subplots on the current figure
%
%    [FIG,SUB] = CHARTGRID(DOWN,ACROSS,DIST)  puts DOWN-by-ACROSS regularly
%    spaced subplots on the figure; DIST is a 6-element numeric vector
%    containing, in this order:
%    - left margin
%    - bottom margin
%    - width of area occupied by plots
%    - height of area occupied by plots
%    - horizontal gap between plots
%    - vertical gap between plots
%
%    If DIST is omitted, default spacing values are used. FIG and SUB are
%    handles to the figure and subplots, respectively. If a figure is not
%    available, a new one is created. All distances are in 'norm' units.
%
%    [FIG,SUB] = CHARTGRID(POSITIONS) creates individually positioned
%    subplots as specified by POSITIONS, a four-column numeric matrix where
%    each row defines a subplot and the columns specify, respectively:
%    - distance from left margin of figure
%    - distance from bottom margin of figure
%    - width of subplot
%    - height of subplot
% 
% Last modified: 25 Jun 15

% last major changes: 17 apr 99
% 22 apr 01: default DIST added
% 29 apr 01: default values changed
%  1 sep 03: default values modified
% 19 sep 03: use current figure if available
%  4 Sep 06: numel replaces prod(size())
% 25 Jun 15: replace scatter with scatplot to prevent naming confusions

fig = gcf;
uni = get (fig, 'units');
set (fig, 'units', 'normalized');

switch nargin
   case 1
      sub = scatplot (down);
   case 2
      sub = grid (down, across, [.1 .1 .85 .8 .05 .05]);
   case 3
      sub = grid (down, across, dist);
   otherwise
      error ('wrong number of arguments')
end
set (fig, 'units', uni);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sub = scatplot (positions)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[numofch, position] = size (positions);
if position ~= 4
   error ('POSITIONS argument must be a 4-column matrix');
end

for i = 1:numofch
   sub(i) = axes('position', positions (i,:));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sub = grid (down, across, dist)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if numel(dist) ~= 6
   error ('DIST must be a six-element vector');
end

left = dist (1);
bottom = dist (2);
width = dist (3);
height = dist (4);
interX = dist (5);
interY = dist (6);

plotwidth = (width - interX * (across-1)) / across;
plotheight = (height - interY * (down-1)) / down;

n=0;
for i=down:-1:1
   for j=1:across
      n=n+1;
      sub(n) = axes ('position', [...
            left+(plotwidth+interX)*(j-1),...
            bottom+(plotheight+interY)*(i-1),...   
            plotwidth,...
            plotheight]...
         );
   end
end
