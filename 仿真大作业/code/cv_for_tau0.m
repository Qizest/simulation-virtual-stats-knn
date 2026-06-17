function k_opt = cv_for_tau0(data, tau0, k_range, N_local)
% 针对单个 tau0 的局部 LORO CV，使用自适应窗口（固定最近邻点数）
% data: cell array of replications
% tau0: 目标时间点
% k_range: 候选 k 向量
% N_local: 用于确定窗口的最近邻点数（默认30）
% 返回：局部最优 k

if nargin < 4
    N_local = 30;
end

n_reps = length(data);

% ---- 第一步：确定自适应窗口半径 ----
% 从所有复制中收集距离 tau0 最近的 N_local 个点，取其最大距离作为窗口
all_t = [];
for j = 1:n_reps
    all_t = [all_t; data{j}(:,1)];
end
[~, idx] = sort(abs(all_t - tau0));
if length(idx) < N_local
    % 若总点数不足，则使用全部点
    window = max(abs(all_t - tau0));
else
    window = abs(all_t(idx(N_local)) - tau0);
end
% 避免窗口为0（若tau0处有点则取较小值）
if window < 1e-6
    window = 0.1;
end

% ---- 第二步：局部LORO CV ----
emse = inf(size(k_range));
for idx_k = 1:length(k_range)
    k = k_range(idx_k);
    sq_err = 0;
    n_test = 0;
    
    for j = 1:n_reps
        test_t = data{j}(:,1);
        test_y = data{j}(:,2);
        % 只取离 tau0 在窗口内的测试点
        near_idx = abs(test_t - tau0) <= window;
        if sum(near_idx) == 0
            continue;
        end
        test_t_near = test_t(near_idx);
        test_y_near = test_y(near_idx);
        
        % 训练集：除 j 外所有复制（全局）
        train_t = [];
        train_y = [];
        for j2 = 1:n_reps
            if j2 == j
                continue;
            end
            train_t = [train_t; data{j2}(:,1)];
            train_y = [train_y; data{j2}(:,2)];
        end
        
        % 对每个局部测试点进行预测
        for m = 1:length(test_t_near)
            dist = abs(train_t - test_t_near(m));
            [~, s_idx] = sort(dist);
            k_use = min(k, length(s_idx));
            pred = mean(train_y(s_idx(1:k_use)));
            sq_err = sq_err + (test_y_near(m) - pred)^2;
            n_test = n_test + 1;
        end
    end
    
    if n_test > 0
        emse(idx_k) = sq_err / n_test;
    else
        emse(idx_k) = inf;
    end
end

[~, best] = min(emse);
k_opt = k_range(best);
end