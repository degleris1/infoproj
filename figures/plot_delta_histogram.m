%% Delta Coding Sanity check
%  First, we'll plot histograms of the values to see how much we have to
%  gain from delta coding. For both the true values and the first
%  differences, we randomly sample 100k values.

% Load raw data
clear all; close all;
fn = '../data/rawDataSample.bin'; 
fid = fopen(fn, 'r'); 
dat = fread(fid, [385 Inf], '*int16');
fclose(fid);

%%
% take first differences along rows and flatten
diffs = vec(diff(dat, 1, 2));
diffs = cast(diffs, 'double');

%%
% get 100k random values from diff
num_samples = 10e4;
rng(123) % seed so that we get the same values
diff_samples = datasample(diffs, num_samples, 'replace', false);

figure;
histogram(diff_samples)
title('Histogram of differences between adjacent elements')
xlabel('Difference')
ylabel('Frequency')
savefig('histogram_diff_values')

% repeat for the raw values
raw_vals = cast(vec(dat), 'double');
rng(123) % same seed
raw_samples = datasample(raw_vals, num_samples, 'replace', false);

figure;
histogram(raw_samples)
title('Histogram of raw values')
xlabel('Value')
ylabel('Frequency')
savefig('histogram_raw_values')