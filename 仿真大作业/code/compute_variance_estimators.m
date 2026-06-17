function [var_sample, var_bootstrap] = compute_variance_estimators(data, tau0, k, B)
% 返回两种方差估计器
% B: bootstrap 重采样次数（推荐 2000）

    % Sample variance
    all_t = [];
    all_y = [];
    for j = 1:length(data)
        all_t = [all_t; data{j}(:,1)];
        all_y = [all_y; data{j}(:,2)];
    end
    [~, idx] = sort(abs(all_t - tau0));
    nearest_y = all_y(idx(1:k));
    var_sample = var(nearest_y) / k;
    
    % Bootstrap variance
    n = length(data);
    boot_v = zeros(B, 1);
    for b = 1:B
        % 有放回抽样 n 个 replication
        idx_boot = randi(n, n, 1);
        boot_data = data(idx_boot);
        boot_v(b) = knn_point_estimator(boot_data, tau0, k);
    end
    var_bootstrap = var(boot_v);
    
    fprintf('  Sample var = %.6f    Bootstrap var = %.6f\n', var_sample, var_bootstrap);
end