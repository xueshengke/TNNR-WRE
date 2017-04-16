function [result, X_rec] = TNNR_WRE_algorithm(result_dir, image_name, X_full, mask, para)
%--------------------------------------------------------------------------
% Xue Shengke, Zhejiang University, April 2017.
% Contact information: see readme.txt.
%
% Liu et al. (2016) TNNR-WRE paper, IEEE Transactions on Image Processing.
%--------------------------------------------------------------------------
%     main part of TNNR-WRE algorithm
% 
%     Inputs:
%         result_dir           --- result directory for saving figures
%         image_name           --- name of image file
%         X_full               --- original image
%         mask                 --- index matrix of known elements
%         para                 --- struct of parameters
% 
%     Outputs: 
%         result               --- result of algorithm
%         X_rec                --- recovered image under the best rank
%--------------------------------------------------------------------------

X_miss = X_full .* mask;	  % incomplete image with some pixels lost
[m, n, dim] = size(X_full);
known = mask(:, :, 1);        % index matrix of known elements
missing = ones(m,n) - known;  % index matrix of missing elements

min_R    = para.min_R;        % minimum rank of chosen image
max_R    = para.max_R;        % maximum rank of chosen image
max_iter = para.max_iter;     % number of max iteration
tol      = para.epsilon;      % tolerance
alpha_0  = para.alpha;        % initial value of alpha
rho      = para.rho; 

W1_inc = weight_matrix(m, para.L, para.theta1);  % weight in ascent order
W1_sort = weight_sort(known, W1_inc);            % weight sorted
W2_inc = weight_matrix(m, para.L, para.theta2);  % weight in ascent order
W2_sort = weight_sort(known, W2_inc);            % weight sorted

Erec = zeros(max_R, 1);  % reconstruction error, best value in each rank
Psnr = zeros(max_R, 1);  % PSNR, best value in each rank
time_cost = zeros(max_R, 1);        % consuming time, each rank
iter_cost = zeros(max_R, dim);      % number of iterations, each channel
X_rec = zeros(m, n, dim, max_iter); % recovered image under the best rank

best_rank = 0;  % record the best value
best_psnr = 0;
best_erec = 0;

figure;
subplot(1,3,1);
imshow(X_full ./ 255);   % show the original image
xlabel('original image');

subplot(1,3,2);
imshow(X_miss ./ 255);   % show the incomplete image
xlabel('incomplete image');

%% main loop
for R = min_R : max_R    % test if each rank is proper for completion
    t_rank = tic;
    X_iter = zeros(m, n, dim, max_iter);
    X_temp = zeros(m, n, dim);
    for c = 1 : dim    % process each channel separately
        fprintf('rank(r)=%d, channel(RGB)=%d \n', R, c);
        X = X_miss(:, :, c);
        M = X_full(:, :, c);
        M_fro = norm(M, 'fro');
        last_X = X;
        delta = inf;
        alpha = alpha_0;
        for i = 1 : max_iter
            fprintf('iter %d, ', i);
            [U, sigma, V] = svd(X);
            A = U'; B = V';
            C = U(:, 1:R)'; D = V(:, 1:R)'; 
            
            X = X - 1/alpha * (W1_sort*A'*B - W2_sort*C'*D);
            X = X .* missing + M .* known;
            X_iter(:, :, c, i) = X;
            
            alpha = rho * alpha;
            iter_cost(R, c) = iter_cost(R, c) + 1;
            
            delta = norm(X - last_X, 'fro') / M_fro;
            fprintf('||X_k+1-X_k||_F/||M||_F %.4f\n', delta);
            if delta < tol
                break ;
            end
            last_X = X;
        end
        X_temp(:, :, c) = X;
    end
    time_cost(R) = toc(t_rank);
    X_temp = max(X_temp, 0);
    X_temp = min(X_temp, 255);
    [Erec(R), Psnr(R)] = PSNR(X_full, X_temp, missing);
    if best_psnr < Psnr(R)
        best_rank = R;
        best_psnr = Psnr(R);
        best_erec = Erec(R);
        X_rec = X_iter;
    end
end
%% compute the reconstruction error and PSNR in each iteration 
%  for the best rank
num_iter = min(iter_cost(best_rank, :));
psnr_iter = zeros(num_iter, 1);
erec_iter = zeros(num_iter, 1);
for t = 1 : num_iter
    X_temp = X_rec(:, :, :, t);
    [erec_iter(t), psnr_iter(t)] = PSNR(X_full, X_temp, missing);
end
X_best_rec = X_rec(:, :, :, num_iter);

%% display recovered image
subplot(1, 3, 3);
X_best_rec = max(X_best_rec, 0);
X_best_rec = min(X_best_rec, 255);
imshow(X_best_rec ./ 255);    % show the recovered image
xlabel('recovered image');

%% save eps figure in result directory
if para.save_eps
    fig_eps = figure;
    imshow(X_best_rec ./ 255, 'border', 'tight');
    split_name = regexp(image_name, '[.]', 'split');
    fig_name = sprintf('%s/%s_rank_%d_PSNR_%.2f_Erec_%.2f', ...
        result_dir, split_name{1}, best_rank, best_psnr, best_erec);
    saveas(gcf, [fig_name '.eps'], 'psc2');
    fprintf('eps figure saved in %s.eps\n', fig_name);
    close(fig_eps);
end

%% record performances for output
result.time = time_cost;
result.iterations = iter_cost;
result.best_rank = best_rank;
result.best_psnr = best_psnr;
result.best_erec = best_erec;
result.Rank = (min_R : max_R)';
result.Psnr = Psnr(min_R:max_R);
result.Erec = Erec(min_R:max_R);
result.Psnr_iter = psnr_iter;
result.Erec_iter = erec_iter;

end