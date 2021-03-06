function [ W_sort ] = weight_sort( mask, W_inc )
%--------------------------------------------------------------------------
% Xue Shengke, Zhejiang University, April 2017.
% Contact information: see readme.txt.
%
% Liu et al. (2016) TNNR-WRE paper, IEEE Transactions on Image Processing.
%--------------------------------------------------------------------------
%     compute an sorted weight matrix according to known elements, rows 
%     with more observed elements are given smaller weights
% 
%     Inputs:
%         mask               --- index matrix of known elements
%         W_inc              --- increasing weight matrix
% 
%     Outputs: 
%         W_sort             --- sorted weight matrix
%--------------------------------------------------------------------------

N_ori = sum(mask, 2);
[N_sort, index] = sort(N_ori, 'descend');
[~, index_back] = sort(index, 'ascend');

inc_weight = diag(W_inc);
sorted_weight = inc_weight(index_back);
W_sort = diag(sorted_weight);

end

