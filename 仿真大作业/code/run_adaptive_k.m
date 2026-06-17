%% run_adaptive_k.m
% 自适应 k*（每个 tau0 独立选 k），使用自适应窗口（固定最近邻点数）
% 保存结果到 result_案例名_adaptive_k.mat

clear; clc;

% 加载案例库
cases = case_parameters();

% 显示案例列表
for i = 1:length(cases)
    fprintf('%2d: %s\n', i, cases(i).name);
end
case_idx = input('请输入要运行的案例序号：');
if isempty(case_idx) || case_idx < 1 || case_idx > length(cases)
    error('无效序号');
end
cfg = cases(case_idx);

% ----- 用户可调参数 -----
R = 100;                % 宏复制次数
n_large_true = 500;     % 真值用大样本
N_local = 30;           % 自适应窗口的最近邻点数（越大越稳定，但局部性越弱）
default_k_range = '1:5:200';
k_input = input(sprintf('请输入 k_range（默认 %s）：', default_k_range), 's');
if isempty(k_input)
    k_range = eval(default_k_range);
else
    k_range = eval(k_input);
end

fprintf('\n========== 运行自适应 k* (自适应窗口) 案例: %s ==========\n', cfg.name);
fprintf('N_local = %d\n', N_local);

% ---- 生成数据 ----
data_all = cell(R, cfg.n);
fprintf('生成 %d 个宏复制数据...\n', R);
for r = 1:R
    for j = 1:cfg.n
        [t_arr, Y_wait] = simulate_one_replication((r-1)*cfg.n + j, cfg.mu, cfg.s, cfg.c, ...
            cfg.arrival_type, cfg.p, cfg.T_end, cfg.rate_type, cfg.service_dist);
        data_all{r,j} = [t_arr' Y_wait'];
    end
    if mod(r,10)==0
        fprintf('  宏复制 %d/%d\n', r, R);
    end
end

% ---- 计算真值 ----
v_true = compute_empirical_true(cfg.tau0_vec, cfg.mu, cfg.c, cfg.arrival_type, cfg.p, ...
    n_large_true, cfg.T_end, cfg.rate_type, cfg.service_dist);

% ---- 预分配 ----
tau = cfg.tau0_vec;
n_tau = length(tau);
v_knn_all = zeros(R, n_tau);
k_star_all = zeros(R, n_tau);

% ---- 对每个宏复制，对每个 tau0 进行局部 CV ----
fprintf('\n开始自适应 k* 估计...\n');
for r = 1:R
    data = data_all(r, :);
    fprintf('宏复制 %d/%d\n', r, R);
    for i = 1:n_tau
        tau0 = tau(i);
        k_opt = cv_for_tau0(data, tau0, k_range, N_local);
        k_star_all(r,i) = k_opt;
        v_knn_all(r,i) = knn_point_estimator(data, tau0, k_opt);
    end
end

% ---- 汇总结果 ----
res = struct();
res.cfg = cfg;
res.v_true = v_true;
res.v_knn_all = v_knn_all;
res.v_knn_mean = mean(v_knn_all,1);
res.k_star_all = k_star_all;
res.k_star_mean = mean(k_star_all,1);
res.improvement = 'adaptive_k_adaptive_window';
res.n_reps = cfg.n;
res.R = R;
res.k_range = k_range;
res.N_local = N_local;

filename = sprintf('result_%s_adaptive_k.mat', cfg.name);
save(filename, 'res');
fprintf('✅ 结果已保存至 %s\n', filename);