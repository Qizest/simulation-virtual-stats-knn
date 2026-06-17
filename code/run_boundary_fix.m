%% run_boundary_reflection.m
% 边界反射法 kNN（在边界处生成虚拟镜像点）

clear; clc;

% 加载案例库
cases = case_parameters();
for i = 1:length(cases)
    fprintf('%2d: %s\n', i, cases(i).name);
end
case_idx = input('请输入要运行的案例序号：');
if isempty(case_idx) || case_idx < 1 || case_idx > length(cases)
    error('无效序号');
end
cfg = cases(case_idx);

% 固定参数
R = 100;
n_large_true = 500;
boundary_thresh = 2;   % 边界阈值，距离边界2以内启用反射

default_k_range = '1:5:200';
k_input = input(sprintf('请输入 k_range（默认 %s）：', default_k_range), 's');
if isempty(k_input)
    k_range = eval(default_k_range);
else
    k_range = eval(k_input);
end

fprintf('\n========== 运行边界反射法 kNN: %s ==========\n', cfg.name);
fprintf('k_range = [%d:%d:%d]\n', min(k_range), k_range(2)-k_range(1), max(k_range));
fprintf('边界阈值: %d\n', boundary_thresh);

% 生成数据
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

% 计算真值
v_true = compute_empirical_true(cfg.tau0_vec, cfg.mu, cfg.c, cfg.arrival_type, cfg.p, ...
    n_large_true, cfg.T_end, cfg.rate_type, cfg.service_dist);

% 预分配
tau = cfg.tau0_vec;
v_knn_all = zeros(R, length(tau));
k_star_all = zeros(R, 1);

% 对每个宏复制：先选全局 k*，再用反射法估计
fprintf('\n开始边界反射法 kNN 估计...\n');
k_star_list = zeros(R, 1);
for r = 1:R
    data = data_all(r, :);
    
    % 选择全局最优 k（使用标准 LORO CV）
    k_global = loro_cv(data, k_range);
    k_star_all(r) = k_global;
    k_star_list(r) = k_global;
    
    % 使用反射法估计所有 tau0
    for i = 1:length(tau)
        tau0 = tau(i);
        v_knn_all(r,i) = knn_reflection_estimator(data, tau0, k_global, cfg.T_end, boundary_thresh);
    end
    
    if mod(r, 5) == 0 || r == R
        fprintf('  宏复制 %d/%d 完成 (k=%d)\n', r, R, k_global);
    end
end

% 输出 k* 统计信息
fprintf('\n====== k* 统计信息 ======\n');
fprintf('平均 k*: %.2f\n', mean(k_star_list));
fprintf('k* 标准差: %.2f\n', std(k_star_list));
fprintf('最小 k*: %d\n', min(k_star_list));
fprintf('最大 k*: %d\n', max(k_star_list));

% 汇总结果
res = struct();
res.cfg = cfg;
res.v_true = v_true;
res.v_knn_all = v_knn_all;
res.v_knn_mean = mean(v_knn_all,1);
res.improvement = 'reflection_method';
res.n_reps = cfg.n;
res.R = R;
res.k_range = k_range;
res.k_star_knn_all = k_star_all;
res.k_star_knn_mean = mean(k_star_all);
res.k_star_knn_std = std(k_star_all);
res.boundary_thresh = boundary_thresh;

filename = sprintf('result_%s_reflection.mat', cfg.name);
save(filename, 'res');
fprintf('✅ 边界反射法结果已保存至 %s\n', filename);