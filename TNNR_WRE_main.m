% Shengke Xue, Zhejiang University, April 2017. 
% Contact information: see readme.txt.
%
% Reference: 
% Liu, Q., Lai, Z., Zhou, Z., Kuang, F., & Jin, Z. (2016). A truncated 
% nuclear norm regularization method based on weighted residual error for 
% matrix completion. IEEE Transactions on Image Processing, 25(1), 316-330.
% 
% Partially composed of Hu et al. (2013) TNNR implementation, written by 
% debingzhang, Zhejiang Universiy, November 2012.

%% add path
close all; clear ; clc;
addpath image ;
addpath mask ;
addpath function;

%% read image files directory information
result_dir = './result/image';
if ~exist(result_dir, 'dir'),   mkdir(result_dir); end
image_list = {'re1.jpg', 're2.jpg', 're3.jpg', 're4.jpg', 're5.jpg', ...
              're6.jpg', 're7.jpg', 're8.jpg', 're9.jpg', 're10.jpg', ...
              're11.jpg' };

%% read mask files directory information
file_list = dir('mask');
num_mask = length(file_list) - 2;
mask_list = cell(num_mask, 1);
for i = 1 : num_mask
    mask_list{i} = file_list(i+2).name;
end

%% parameter configuration
image_id = 8;            % select an image for experiment
mask_id  = 1;            % select a mask for experiment

para.block = 0;          % 1 for block occlusion, 0 for random noise
para.lost = 0.40;        % percentage of lost elements in matrix
para.save_eps = 1;       % save eps figure in result directory
para.min_R = 1;          % minimum rank of chosen image
para.max_R = 20;         % maximum rank of chosen image
% it requires to test all ranks from min_R to max_R, note that different
% images have different ranks, and various masks affect the ranks, too.

para.max_iter = 200;     % maximum number of iteration
para.epsilon = 1e-4;     % tolerance of iteration

para.alpha = 5e-4;       % 1/apha, positive step size of gradient descent
para.rho   = 1.15;       % rho > 1, scale up the value of alpha
para.theta1 = 1.0;       % compute an increasing weight matrix, W1 >= W2
para.theta2 = 1.0;         % if theta = 1, W = I, an indentity matrix
para.L     = 150;        % 1 <= L <= m, compute W
para.progress = 0;

%% select an image and a mask for experiment
image_name = image_list{image_id};
X_full = double(imread(image_name));
[m, n, dim] = size(X_full);
fprintf('choose image: %s, ', image_name);

if para.block  
    % block occlusion
    mask = double(imread(mask_list{mask_id}));
    mask = mask ./ max(mask(:));       % index matrix of the known elements
    fprintf('mask: %s.\n', mask_list{mask_id});
else
    % random loss
%     rnd_idx = randi([0, 100-1], m, n);
%     old_idx = rnd_idx;
%     lost = para.lost * 100;
%     fprintf('loss: %d%% elements are missing.\n', lost);
%     rnd_idx = double(old_idx < (100-lost));
%     mask = repmat(rnd_idx, [1 1 dim]); % index matrix of the known elements
    
    rnd_idx = randi([0, 100-1], m, n, dim);
    old_idx = rnd_idx;
    lost = para.lost * 100;
    fprintf('loss: %d%% elements are missing.\n', lost);
    rnd_idx = double(old_idx < (100-lost));
    mask = rnd_idx; % index matrix of the known elements    
end

%% Truncated Nuclear Norm, based on Weighted Residual Error
fprintf(['Truncated Nuclear Norm Regularization Method Based on Weighted ' ...
         'Residual Error for Matrix Completion\n']);
t1 = tic;
[tnnr_res, X_rec]= TNNR_WRE_algorithm(result_dir, image_name, X_full, mask, para);
toc(t1);

tnnr_rank = tnnr_res.best_rank;
tnnr_psnr = tnnr_res.best_psnr;
tnnr_erec = tnnr_res.best_erec;
tnnr_time_cost = tnnr_res.time(tnnr_rank);
tnnr_iteration = tnnr_res.iterations(tnnr_rank, :);

fprintf('\nrank=%d, psnr=%f, erec=%f, time=%f s, iteration=(%d,%d,%d)\n', ...
    tnnr_rank, tnnr_psnr, tnnr_erec, tnnr_time_cost, tnnr_iteration(1), ...
    tnnr_iteration(2), tnnr_iteration(3));
disp(' ');

figure;
subplot(2, 2, 1);
plot(tnnr_res.Rank, tnnr_res.Psnr, 'o-');
xlabel('Rank');
ylabel('PSNR');

subplot(2, 2, 2);
plot(tnnr_res.Rank, tnnr_res.Erec, 'diamond-');
xlabel('Rank');
ylabel('Recovery error');

subplot(2, 2, 3);
plot(tnnr_res.Psnr_iter, 'square-');
xlabel('Iteration');
ylabel('PSNR');

subplot(2, 2, 4);
plot(tnnr_res.Erec_iter, '^-');
xlabel('Iteration');
ylabel('Recovery error');

if para.progress
    figure('NumberTitle', 'off', 'Name', 'TNNR-WRE progress');
    num_iter = min(tnnr_iteration);
    X_rec = X_rec / 255;
    for i = 1 : num_iter
        imshow(X_rec(:, :, :, i));
        title(['iter ' num2str(i)]);
    end    % better set a breakpoint here, to display image step by step
end

%% record test results
outputFileName = fullfile(result_dir, 'parameters.txt'); 
fid = fopen(outputFileName, 'a') ;
fprintf(fid, '****** %s ******\n', datestr(now,0));
fprintf(fid, '%s\n', ['image: '           image_name               ]);
fprintf(fid, '%s\n', ['mask: '            mask_list{mask_id}       ]);
fprintf(fid, '%s\n', ['block or noise: '  num2str(para.block)      ]);
fprintf(fid, '%s\n', ['loss ratio: '      num2str(para.lost)       ]);
fprintf(fid, '%s\n', ['save eps figure: ' num2str(para.save_eps)   ]);
fprintf(fid, '%s\n', ['min rank: '        num2str(para.min_R)      ]);
fprintf(fid, '%s\n', ['max rank: '        num2str(para.max_R)      ]);
fprintf(fid, '%s\n', ['max iteration: '   num2str(para.max_iter)   ]);
fprintf(fid, '%s\n', ['tolerance: '       num2str(para.epsilon)    ]);
fprintf(fid, '%s\n', ['alpha: '           num2str(para.alpha)      ]);
fprintf(fid, '%s\n', ['rho: '             num2str(para.rho)        ]);
fprintf(fid, '%s\n', ['theta1: '          num2str(para.theta1)     ]);
fprintf(fid, '%s\n', ['theta2: '          num2str(para.theta2)     ]);
fprintf(fid, '%s\n', ['L: '               num2str(para.L)          ]);

fprintf(fid, '%s\n', ['rank: '            num2str(tnnr_rank)       ]);
fprintf(fid, '%s\n', ['psnr: '            num2str(tnnr_psnr)       ]);
fprintf(fid, '%s\n', ['recovery error: '  num2str(tnnr_erec)       ]);
fprintf(fid, '%s\n', ['time cost: '       num2str(tnnr_time_cost)  ]);
fprintf(fid, 'iteration: %d, %d, %d\n',   tnnr_iteration(1), ...
    tnnr_iteration(2), tnnr_iteration(3));

fprintf(fid, '--------------------\n');
fclose(fid);
