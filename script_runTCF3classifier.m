%___________________________________________________
%   Applying the classifier
%___________________________________________________

% get the top selected genes from the data in the same order as were used
% in the classifier. The genenames are stored in the selected_genes variable
% in the classifier, he '-' in the gene names was replaced with '_', so
% need to replace it back
selected_genes = strrep(trainedClassifier_TCF3targets.ClassificationKNN.ExpandedPredictorNames, '_', '-');

% indicate the first row where the expression data starts
% e.g., if your data has a header, then data may start at row 2
rowWhereDataStarts = 2; 
% indicate the first columns there the expression data starts
% e.g. if you have gene names and gene IDs as first 2 columns, then the
% data may start at column 3
colWhereDataStarts = 3;
columnWithGeneNames = 2; %column # with the gene names

%extract the selected genes in the order they were used in the classifier -
%indicated by the 'stable' parameter
[~, ~, indB] = intersect(selected_genes, yourdata(rowWhereDataStarts:end, columnWithGeneNames), 'stable');
notfound = setdiff(selected_genes, yourdata(rowWhereDataStarts:end, columnWithGeneNames));
%check that notfound is empty - if it is not, check which genes were not
%found in your dataset. Alternatively look for synonims.

% preprocess your data the same way as the training set
%the data must be log2 transformed and minmax standardized across the 
t = cell2mat(yourdata(indB+rowWhereDataStarts, colWhereDataStarts:end));
t = log2(replaceZeros(t, 'lowval'));
t = minmax_standardize(t, 2);


%run classifier to classify the samples into cluster A or B, the results is
%1 = group A, 0 = group B
subtypeClass = trainedClassifier_TCF3targets.predictFcn(t); 
