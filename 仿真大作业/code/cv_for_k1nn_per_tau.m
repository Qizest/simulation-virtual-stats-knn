function k_star_vec = cv_for_k1nn_per_tau(data, tau_vec, k_range)
% 为每个 τ₀ 独立选择最优 k（留一复制法）
% data: cell array of replications, each cell = [t, Y] matrix
% tau_vec: vector of τ₀ values
% k_range: vector of candidate k (建议 1:n)
% 输出：与 tau_vec 等长的向量，每个 τ₀ 的最优 k

    n_reps = length(data);
    n_tau = length(tau_vec);
    
    % 预计算每个复制在每个 τ₀ 下的最近邻点 [distance, Y]
    nearest = cell(n_reps, n_tau);
    for j = 1:n_reps
        t_j = data{j}(:,1);
        y_j = data{j}(:,2);
        for i = 1:n_tau
            tau0 = tau_vec(i);
            [dist, idx] = min(abs(t_j - tau0));
            nearest{j,i} = [dist, y_j(idx)];
        end
    end
    
    k_star_vec = zeros(1, n_tau);
    for i = 1:n_tau
        EMSE = zeros(size(k_range));
        for idx_k = 1:length(k_range)
            k = k_range(idx_k);
            sq_err = 0;
            for j = 1:n_reps
                test_y = nearest{j,i}(2);
                % 训练集：除 j 外所有复制在同一 τ₀ 下的最近邻点
                train_y = [];
                dist_train = [];
                for j2 = 1:n_reps
                    if j2 == j, continue; end
                    train_y = [train_y; nearest{j2,i}(2)];
                    dist_train = [dist_train; nearest{j2,i}(1)];
                end
                if isempty(train_y), continue; end
                [~, idx_sort] = sort(dist_train);
                k_use = min(k, length(train_y));
                pred = mean(train_y(idx_sort(1:k_use)));
                sq_err = sq_err + (test_y - pred)^2;
            end
            EMSE(idx_k) = sq_err / n_reps;
        end
        [~, best_idx] = min(EMSE);
        k_star_vec(i) = k_range(best_idx);
    end
end