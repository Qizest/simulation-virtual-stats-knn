%% run_weighted_knn.m
% 加权 kNN 实验（独立选择全局最优 k*）

clear; clc;

% 加载案例库
cases = case_parameters();

% 显示案例列表
fprintf('可用案例：\n');
for i = 1:length(cases)
    fprintf('  %2d: %s\n', i, cases(i).name);
end

% 用户输入案例序号
case_idx = input('请输入要运行的案例序号：');
if isempty(case_idx) || case_idx < 1 || case_idx > length(cases)
    error('无效序号');
end
cfg = cases(case_idx);

% 固定参数
R = 100;               % 宏复制次数
n_large_true = 500;    % 真值计算用大复制数

% 手动输入 k_range
default_k_range = '1:5:200';
k_input = input(sprintf('请输入 knn 的 k_range（例如 [10:10:500]），直接回车使用默认 %s：', default_k_range), 's');
if isempty(k_input)
    k_range = eval(default_k_range);
else
    k_range = eval(k_input);
    if ~isvector(k_range) || length(k_range) < 2
        error('k范围必须为向量');
    end
end

fprintf('\n========== 运行加权 kNN 案例: %s ==========\n', cfg.name);
fprintf('参数: mu=%.1f, s=%d, c=%d, n=%d, arrival=%s, service=%s, rate=%s\n', ...
        cfg.mu, cfg.s, cfg.c, cfg.n, cfg.arrival_type, cfg.service_dist, cfg.rate_type);
fprintf('模式: 独立选择全局 k*（严谨）\n');
fprintf('k_range = [%d:%d:%d]\n', min(k_range), k_range(2)-k_range(1), max(k_range));

% ------------------------- 生成所有宏复制数据 -------------------------
data_all = cell(R, cfg.n);
fprintf('  正在生成 %d 个宏复制的数据...\n', R);
for r = 1:R
    for j = 1:cfg.n
        [t_arr, Y_wait] = simulate_one_replication((r-1)*cfg.n + j, cfg.mu, cfg.s, cfg.c, ...
            cfg.arrival_type, cfg.p, cfg.T_end, cfg.rate_type, cfg.service_dist);
        data_all{r,j} = [t_arr' Y_wait'];
    end
    if mod(r,10)==0
        fprintf('    数据生成宏复制 %d/%d\n', r, R);
    end
end

% ------------------------- 计算经验真值 -------------------------
fprintf('  计算经验真值...\n');
v_true = compute_empirical_true(cfg.tau0_vec, cfg.mu, cfg.c, cfg.arrival_type, cfg.p, ...
    n_large_true, cfg.T_end, cfg.rate_type, cfg.service_dist);
fprintf('✅ 经验真值计算完成！\n');

% ------------------------- 预分配存储 -------------------------
tau = cfg.tau0_vec;
v_knn_all = zeros(R, length(tau));
k_star_all = zeros(R, 1);   % 记录每个宏复制选出的全局最优 k

% ------------------------- 对每个宏复制：先求全局最优 k，再加权估计 -------------------------
fprintf('\n  开始加权 kNN 估计（每个宏复制独立 LORO CV 选择全局 k*）...\n');
for r = 1:R
    data = data_all(r, :);
    
    % 选择全局最优 k（使用 LORO CV）
    k_global = loro_cv(data, k_range);
    k_star_all(r) = k_global;
    
    % 对该宏复制所有 tau0 使用加权估计
    for i = 1:length(tau)
        tau0 = tau(i);
        v_knn_all(r,i) = knn_weighted_estimator(data, tau0, k_global);
    end
    
    if mod(r, 5) == 0 || r == R
        fprintf('  宏复制 %d/%d 完成 (k=%d)\n', r, R, k_global);
    end
end

% ------------------------- 汇总结果 -------------------------
res = struct();
res.cfg = cfg;
res.v_true = v_true;
res.v_knn_all = v_knn_all;
res.v_knn_mean = mean(v_knn_all,1);
res.improvement = 'weighted_knn';
res.n_reps = cfg.n;
res.R = R;
res.n_large_true = n_large_true;
res.k_range = k_range;
res.k_star_knn_all = k_star_all;          % 记录选择的 k 值
res.k_star_knn_mean = mean(k_star_all);

filename = sprintf('result_%s_weighted_knn.mat', cfg.name);
save(filename, 'res');
fprintf('✅ 加权 kNN 案例 %s 运行完成，结果已保存至 %s\n', cfg.name, filename);

% ==================== 内部辅助函数 ====================
function v_hat = knn_weighted_estimator(data, tau0, k)
    % 逆距离加权 kNN 估计
    all_t = []; all_y = [];
    for j = 1:length(data)
        if ~isempty(data{j})
            all_t = [all_t; data{j}(:,1)];
            all_y = [all_y; data{j}(:,2)];
        end
    end
    if isempty(all_t)
        v_hat = NaN;
        return;
    end
    dist = abs(all_t - tau0);
    [~, idx] = sort(dist);
    k = min(k, length(idx));
    nearest_d = dist(idx(1:k));
    nearest_y = all_y(idx(1:k));
    weights = 1 ./ (nearest_d + 1e-10);
    weights = weights / sum(weights);
    v_hat = sum(weights .* nearest_y);
end