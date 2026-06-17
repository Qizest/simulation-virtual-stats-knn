%% 运行单个案例
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

% 用户输入 knn 的 k_range（较密）
k_input = input('请输入 knn 的 k_range（例如 [10:10:500]），直接回车使用默认 [10:10:500]：', 's');
if isempty(k_input)
    k_range_knn = 10:10:500;
else
    k_range_knn = eval(k_input);
end

% 为 k-of-1nn 单独设置候选范围
k_range_k1nn = 1:1;

% 实验参数
R = 100;
B = 2000;
n_large_true = 500;
fprintf('\n========== 运行案例 %d: %s ==========\n', case_idx, cfg.name);
fprintf('参数: mu=%.1f, s=%d, c=%d, n=%d, arrival=%s, service=%s, rate=%s\n', ...
        cfg.mu, cfg.s, cfg.c, cfg.n, cfg.arrival_type, cfg.service_dist, cfg.rate_type);
fprintf('knn 的 k_range = [%d:%d:%d]\n', min(k_range_knn), k_range_knn(2)-k_range_knn(1), max(k_range_knn));
fprintf('k-of-1nn 的 k_range = [%d:%d]\n', min(k_range_k1nn), max(k_range_k1nn));

% ------------------------- 生成所有宏复制数据 -------------------------
data_all = cell(R, cfg.n);
fprintf('  正在生成 %d 个宏复制的数据...\n', R);
for r = 1:R
    fprintf('    宏复制 %d/%d\n', r, R);
    for j = 1:cfg.n
        [t_arr, Y_wait] = simulate_one_replication((r-1)*cfg.n + j, cfg.mu, cfg.s, cfg.c, ...
            cfg.arrival_type, cfg.p, cfg.T_end, cfg.rate_type, cfg.service_dist);
        data_all{r,j} = [t_arr' Y_wait'];
    end
end

% ------------------------- 计算经验真值 -------------------------
v_true = compute_empirical_true(cfg.tau0_vec, cfg.mu, cfg.c, cfg.arrival_type, cfg.p, ...
    n_large_true, cfg.T_end, cfg.rate_type, cfg.service_dist);

% ------------------------- 预分配存储 -------------------------
tau = cfg.tau0_vec;
v_knn_all = zeros(R, length(tau));
v_k1nn_all = zeros(R, length(tau));
var_sample_all = zeros(R, length(tau));
var_boot_all = zeros(R, length(tau));
k_star_knn_all = zeros(R, 1);
k_star_k1nn_all = zeros(R, length(tau));   % R × n_tau
emse_knn_all = zeros(R, length(tau));
emse_k1nn_all = zeros(R, length(tau));

% ------------------------- 对每个宏复制进行 CV 和估计 -------------------------
for r = 1:R
    data = data_all(r, :);
    
    % knn 的 k*（LORO CV）
    fprintf('  宏复制 %d/%d: 运行 LORO CV for knn...\n', r, R);
    k_star_knn = loro_cv(data, k_range_knn);
    k_star_knn_all(r) = k_star_knn;
    
    % k-of-1nn 的 k*（每个 τ0 独立选择）
    fprintf('  宏复制 %d/%d: 运行 CV for k-of-1nn (per τ0)...\n', r, R);
    k_star_k1nn_vec = cv_for_k1nn_per_tau(data, tau, k_range_k1nn);
    k_star_k1nn_all(r, :) = k_star_k1nn_vec;
    
    % 使用各自最优 k 进行估计
    for i = 1:length(tau)
        tau0 = tau(i);
        v_knn_all(r,i) = knn_point_estimator(data, tau0, k_star_knn);
        v_k1nn_all(r,i) = k_of_1nn_estimator(data, tau0, k_star_k1nn_vec(i));
        [var_s, var_b] = compute_variance_estimators(data, tau0, k_star_knn, B);
        var_sample_all(r,i) = var_s;
        var_boot_all(r,i) = var_b;
    end
    emse_knn_all(r,:) = (v_knn_all(r,:) - v_true).^2;
    emse_k1nn_all(r,:) = (v_k1nn_all(r,:) - v_true).^2;
end

% ------------------------- 汇总结果 -------------------------
res = struct();
res.data_all = data_all;
res.cfg = cfg;
res.k_range_knn = k_range_knn;
res.k_range_k1nn = k_range_k1nn;
res.R = R;
res.B = B;
res.n_large_true = n_large_true;
res.tau0_vec = tau;
res.v_true = v_true;
res.v_knn_all = v_knn_all;
res.v_k1nn_all = v_k1nn_all;
res.var_sample_all = var_sample_all;
res.var_boot_all = var_boot_all;
res.k_star_knn_all = k_star_knn_all;
res.k_star_k1nn_all = k_star_k1nn_all;
res.emse_knn_all = emse_knn_all;
res.emse_k1nn_all = emse_k1nn_all;
res.v_knn_mean = mean(v_knn_all,1);
res.v_k1nn_mean = mean(v_k1nn_all,1);
res.k_star_knn_mean = mean(k_star_knn_all);
res.k_star_knn_std = std(k_star_knn_all);
res.k_star_k1nn_mean = mean(k_star_k1nn_all, 1);   % 每个 τ0 的平均 k*
res.k_star_k1nn_std = std(k_star_k1nn_all, 0, 1);
res.emse_knn_mean = mean(emse_knn_all,1);
res.emse_k1nn_mean = mean(emse_k1nn_all,1);

% 保存结果
filename = sprintf('result_%s.mat', cfg.name);
save(filename, 'res');
fprintf('✅ 案例 %s 运行完成，结果已保存至 %s\n', cfg.name, filename);