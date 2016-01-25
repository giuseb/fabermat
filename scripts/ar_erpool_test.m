% 21st janaury 2015/ modification of ERPpool by ANdrea
% Giuseppe wants me to create a grafic for each group of Mice (TASTPM and C57, with subplots
% for each mouse).I load the matlab files ex?ported from LAbchart and I create a loop 
clear all; close all
[names,path] = uigetfile('*.mat','Open the source file','MultiSelect', 'on'); % load as many files as you need and memorize their location and name
%% load data
for i=1:length(names);
load(fullfile(path,names{i}), 'data', 'com', 'datastart', 'dataend'); %load first file
first_sample = datastart(2); % Ch2
last_sample  = dataend(2); %Ch2
eeg = data(first_sample:last_sample); % create eeg data signal of 2nd Ch
idx = com(:, 3)' - (70*4);
code = com(:, 5)';

% here we need to collect data for average % 
ep = ERPool(eeg, idx, code);
subplot(2,2,i); ep.plot;
title(names{i});
set(gca,'YDir','reverse');
ylim([-0.2 0.2]);
xlim([-100 500]);
end

%% Giuseppe's suggestions.

clear
close all

% avoid as much as possible the use of "interactive" scripts. In principle,
% we should always pursue the following dichotomy: any procedure that can
% be carried out multiple times, such as an analysis routine that can be
% applied to any number of data files, should be wrapped in a function.
% Scripts are better suited to be part of a journal. They execute a
% procedure on a specific dataset and, especially if properly commented,
% serve as historical memory of what was done, when, and why.
% This is why uigetfile is not a good idea here. It allows you to easily
% locate and pick files of interest, but the script will never tell you
% what you actually did.

% set up "constants". Never use "magic numbers" in your code
channel = 2;
correction = -70*4; % 70 ms wrong offset times KHz
yl = 0.2;  % max potential to use as YLim for all charts
axcol = 2; % number of axes per page column
axrow = 2; % number of axes per page row

% avoid using the word 'path' as a variable name, because path is a Matlab
% function; change the following data path to yours.
% DO NOT USE SPACES IN YOUR PATH OR FILE NAMES!!! (AS I SAID SO MANY TIMES)
data_path = '/Users/giuseppe/data/erp';
% here, we assume that all files in the data_path are to be analyzed
files = dir(data_path);

for f = 3:length(files) % entries 1-2 are the current and the parent dirs
   load(fullfile(data_path, files(f).name), 'data', 'com', 'datastart', 'dataend');
   % set up ERPool parameters
   eeg   = data(datastart(channel):dataend(channel));
   times = com(:, 3)' + correction;
   codes = com(:, 5)';
   % create ERPool object and specify analysis window
   ep = ERPool(eeg, times, codes, 'base', 100, 'resp', 500);
   % I will recommend the use of chartgrid, a function I wrote, instead of
   % subplot; chartgrid is more flexible and precise in placing axes
   subplot(axrow,axcol,f-2)
   ep.plot
   title(files(f).name);
   set(gca, ...
      'YDir','reverse', ...
      'ylim', [-yl yl])
end

% finally, DO NOT save the figures unless they represent a true, final
% output for a presentation or a paper.
% To show a result, just run the script!