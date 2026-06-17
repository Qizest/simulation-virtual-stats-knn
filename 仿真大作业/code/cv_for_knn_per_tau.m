function k_star_vec = cv_for_knn_per_tau(data, tau_vec, k_range)
% 为每个 τ₀ 通过留一复制 CV 选择最优 k（用于原始 knn 估计器）
% data : 1×n cell，每个元素为 [t, Y] 矩阵
% tau_vec : 目标时间点向量
% k_range : 候选 k 的向量

n_reps = length(data);
n_tau = length(tau_vec);

% 预处理：将所有复制拼接并记录复制号
all_t = []; all_y = []; all_rep = [];
for j = 1:n_reps
    if ~isempty(data{j})
        t_j = data{j}(:,1);
        y_j = data{j}(:,2);
        all_t = [all_t; t_j];
        all_y = [all_y; y_j];
        all_rep = [all_rep; j*ones(length(t_j),1)];
    end
end

k_star_vec = zeros(1, n_tau);
for i = 1:n_tau
    tau0 = tau_vec(i);
    EMSE = zeros(size(k_range));
    for idx_k = 1:length(k_range)
        k = k_range(idx_k);
        sq_err = 0;
        n_test = 0;
        for j = 1:n_reps
            % 测试集：复制 j 的所有点
            test_idx = (all_rep == j);
            if sum(test_idx) == 0, continue; end
            test_t = all_t(test_idx);
            test_y = all_y(test_idx);
            % 训练集：除 j 外所有点
            train_idx = (all_rep ~= j);
            train_t = all_t(train_idx);
            train_y = all_y(train_idx);
            for m = 1:length(test_t)
                dists = abs(train_t - test_t(m));
                [~, s_idx] = sort(dists);
                k_use = min(k, length(s_idx));
                pred = mean(train_y(s_idx(1:k_use)));
                sq_err = sq_err + (test_y(m) - pred)^2;
                n_test = n_test + 1;
            end
        end
        EMSE(idx_k) = sq_err / n_test;
    end
    [~, best] = min(EMSE);
    k_star_vec(i) = k_range(best);
end
end